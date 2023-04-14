import 'dart:convert';

import 'package:butterfly/api/file_system.dart';
import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/cubits/settings.dart';
import 'package:butterfly/dialogs/export.dart';
import 'package:butterfly/models/defaults.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../widgets/header.dart';
import '../import.dart';
import 'pack.dart';

class PacksDialog extends StatefulWidget {
  final bool globalOnly;
  const PacksDialog({super.key, this.globalOnly = false});

  @override
  State<PacksDialog> createState() => _PacksDialogState();
}

class _PacksDialogState extends State<PacksDialog>
    with TickerProviderStateMixin {
  late final TabController _controller;
  late final PackFileSystem _fileSystem;

  @override
  initState() {
    _controller = TabController(length: widget.globalOnly ? 1 : 2, vsync: this);
    _fileSystem = PackFileSystem.fromPlatform(
        remote: context.read<SettingsCubit>().state.getDefaultRemote());
    super.initState();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            Flexible(
              child: Stack(children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Header(
                      title: Text(AppLocalizations.of(context).packs),
                    ),
                    if (!widget.globalOnly)
                      TabBar(
                        controller: _controller,
                        tabs: [
                          Tab(
                            icon: const PhosphorIcon(PhosphorIconsLight.file),
                            text: AppLocalizations.of(context).document,
                          ),
                          Tab(
                            icon: const PhosphorIcon(
                                PhosphorIconsLight.appWindow),
                            text: AppLocalizations.of(context).local,
                          ),
                        ],
                      ),
                    Flexible(
                      child: TabBarView(controller: _controller, children: [
                        if (!widget.globalOnly)
                          BlocBuilder<DocumentBloc, DocumentState>(
                              builder: (context, state) {
                            if (state is! DocumentLoadSuccess) {
                              return Container();
                            }
                            final packs = state.document.packs;
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: packs.length,
                              itemBuilder: (context, index) {
                                final pack = packs[index];
                                return Dismissible(
                                  key: ValueKey('localpack:${pack.name}'),
                                  onDismissed: (direction) {
                                    context
                                        .read<DocumentBloc>()
                                        .add(DocumentPackRemoved(pack.name));
                                  },
                                  background: Container(
                                    color: Colors.red,
                                  ),
                                  child: ListTile(
                                    title: Text(pack.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (pack.author.isNotEmpty)
                                          Text(AppLocalizations.of(context)
                                              .byAuthor(pack.author)),
                                        if (pack.description.isNotEmpty)
                                          Text(pack.description),
                                      ],
                                    ),
                                    onTap: () async {
                                      final bloc = context.read<DocumentBloc>();
                                      Navigator.of(context).pop();
                                      final newPack =
                                          await showDialog<ButterflyPack>(
                                              context: context,
                                              builder: (context) =>
                                                  BlocProvider.value(
                                                      value: bloc,
                                                      child: PackDialog(
                                                          pack: pack)));
                                      if (newPack == null) return;
                                      bloc.add(DocumentPackUpdated(
                                          pack.name, newPack));
                                    },
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          padding: EdgeInsets.zero,
                                          child: ListTile(
                                            leading: const PhosphorIcon(
                                                PhosphorIconsLight.appWindow),
                                            title: Text(
                                                AppLocalizations.of(context)
                                                    .local),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              _addPack(pack, true);
                                            },
                                          ),
                                        ),
                                        PopupMenuItem(
                                          padding: EdgeInsets.zero,
                                          child: ListTile(
                                            leading: const PhosphorIcon(
                                                PhosphorIconsLight.download),
                                            title: Text(
                                                AppLocalizations.of(context)
                                                    .export),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              _exportPack(pack);
                                            },
                                          ),
                                        ),
                                        PopupMenuItem(
                                          padding: EdgeInsets.zero,
                                          child: ListTile(
                                            leading: const PhosphorIcon(
                                                PhosphorIconsLight.trash),
                                            title: Text(
                                                AppLocalizations.of(context)
                                                    .delete),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              context.read<DocumentBloc>().add(
                                                  DocumentPackRemoved(
                                                      pack.name));
                                            },
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {},
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        FutureBuilder<List<ButterflyPack>>(
                          future: _fileSystem
                              .createDefault(context)
                              .then((value) => _fileSystem.getPacks()),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text(snapshot.error.toString());
                            }
                            if (!snapshot.hasData) {
                              return const Align(
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(),
                              );
                            }
                            final globalPacks = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: globalPacks.length,
                              itemBuilder: (context, index) {
                                final pack = globalPacks[index];
                                return Dismissible(
                                  key: ValueKey('globalpack:${pack.name}'),
                                  onDismissed: (direction) async {
                                    await _fileSystem.deletePack(pack.name);
                                    if (mounted) Navigator.of(context).pop();
                                  },
                                  background: Container(
                                    color: Colors.red,
                                  ),
                                  child: ListTile(
                                    title: Text(pack.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (pack.author.isNotEmpty)
                                          Text(AppLocalizations.of(context)
                                              .byAuthor(pack.author)),
                                        if (pack.description.isNotEmpty)
                                          Text(pack.description),
                                      ],
                                    ),
                                    onTap: () async {
                                      final bloc = context.read<DocumentBloc>();
                                      final newPack =
                                          await showDialog<ButterflyPack>(
                                              context: context,
                                              builder: (context) =>
                                                  BlocProvider.value(
                                                    value: bloc,
                                                    child:
                                                        PackDialog(pack: pack),
                                                  ));
                                      if (newPack == null) return;
                                      if (pack.name != newPack.name) {
                                        await _fileSystem.deletePack(pack.name);
                                      }
                                      await _fileSystem.updatePack(newPack);
                                      setState(() {});
                                    },
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        if (!widget.globalOnly)
                                          PopupMenuItem(
                                            padding: EdgeInsets.zero,
                                            child: ListTile(
                                              leading: const PhosphorIcon(
                                                  PhosphorIconsLight.file),
                                              title: Text(
                                                  AppLocalizations.of(context)
                                                      .document),
                                              onTap: () async {
                                                Navigator.of(context).pop();
                                                _addPack(pack, false);
                                              },
                                            ),
                                          ),
                                        PopupMenuItem(
                                          padding: EdgeInsets.zero,
                                          child: ListTile(
                                            leading: const PhosphorIcon(
                                                PhosphorIconsLight.download),
                                            title: Text(
                                                AppLocalizations.of(context)
                                                    .export),
                                            onTap: () async {
                                              Navigator.of(context).pop();
                                              _exportPack(pack);
                                            },
                                          ),
                                        ),
                                        PopupMenuItem(
                                          padding: EdgeInsets.zero,
                                          child: ListTile(
                                            leading: const PhosphorIcon(
                                                PhosphorIconsLight.trash),
                                            title: Text(
                                                AppLocalizations.of(context)
                                                    .delete),
                                            onTap: () async {
                                              await _fileSystem
                                                  .deletePack(pack.name);
                                              if (mounted) {
                                                Navigator.of(context).pop();
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {},
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ]),
                    )
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FloatingActionButton.extended(
                      icon: const PhosphorIcon(PhosphorIconsLight.plus),
                      label: Text(AppLocalizations.of(context).add),
                      onPressed: () {
                        showModalBottomSheet<ThemeMode>(
                          context: context,
                          constraints: const BoxConstraints(maxWidth: 640),
                          builder: (ctx) => Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ListView(shrinkWrap: true, children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 20),
                                child: Text(
                                  AppLocalizations.of(ctx).add,
                                  style: Theme.of(ctx).textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ListTile(
                                title: Text(AppLocalizations.of(ctx).import),
                                leading: const PhosphorIcon(
                                    PhosphorIconsLight.arrowSquareIn),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  final data = await showDialog<String>(
                                    context: ctx,
                                    builder: (context) => const ImportDialog(),
                                  );
                                  if (data == null) return;
                                  final pack = const PackJsonConverter()
                                      .fromJson(json.decode(data));
                                  final success = await showDialog<bool>(
                                        context: this.context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                              AppLocalizations.of(context)
                                                  .sureImportPack),
                                          scrollable: true,
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(pack.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge),
                                              Text(AppLocalizations.of(context)
                                                  .byAuthor(pack.author)),
                                              Text(pack.description),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .cancel),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: Text(
                                                  AppLocalizations.of(context)
                                                      .import),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (!success) return;
                                  _addPack(pack);
                                },
                              ),
                              ListTile(
                                title: Text(AppLocalizations.of(ctx).create),
                                leading: const PhosphorIcon(
                                    PhosphorIconsLight.plusCircle),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  final pack = await showDialog<ButterflyPack>(
                                    context: ctx,
                                    builder: (context) => const PackDialog(),
                                  );
                                  if (pack != null) {
                                    _addPack(pack);
                                  }
                                },
                              ),
                              ListTile(
                                title: Text(
                                    AppLocalizations.of(ctx).importCorePack),
                                subtitle: Text(AppLocalizations.of(ctx)
                                    .importCorePackDescription),
                                leading:
                                    const PhosphorIcon(PhosphorIconsLight.cube),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  final pack =
                                      await DocumentDefaults.getCorePack();
                                  if (_isGlobal()) {
                                    await _fileSystem.deletePack(pack.name);
                                    setState(() {});
                                  } else if (context.mounted) {
                                    final bloc = context.read<DocumentBloc>();
                                    bloc.add(DocumentPackRemoved(pack.name));
                                  }
                                  _addPack(pack);
                                },
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).close),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isGlobal() => _controller.index == 1 || widget.globalOnly;

  Future<void> _addPack(ButterflyPack pack, [bool? global]) async {
    if (global ?? _isGlobal()) {
      await _fileSystem.createPack(pack);
      setState(() {});
    } else {
      context.read<DocumentBloc>().add(DocumentPackAdded(pack));
    }
  }

  Future<void> _exportPack(ButterflyPack pack) async {
    return showDialog(
      context: context,
      builder: (context) => ExportDialog(
        data: json.encode(const PackJsonConverter().toJson(pack)),
      ),
    );
  }
}
