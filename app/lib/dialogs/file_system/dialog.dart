import 'dart:async';

import 'package:butterfly/api/file_system.dart';
import 'package:butterfly/bloc/document_bloc.dart';
import 'package:butterfly/cubits/settings.dart';
import 'package:butterfly/dialogs/file_system/create.dart';
import 'package:butterfly/dialogs/file_system/grid.dart';
import 'package:butterfly/dialogs/file_system/list.dart';
import 'package:butterfly/dialogs/file_system/sync.dart';
import 'package:butterfly/widgets/header.dart';
import 'package:butterfly/widgets/remote_button.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

typedef AssetOpenedCallback = void Function(AppDocumentEntity path);

class FileSystemDialog extends StatefulWidget {
  final DocumentBloc bloc;

  const FileSystemDialog({super.key, required this.bloc});

  @override
  _FileSystemDialogState createState() => _FileSystemDialogState();
}

class _FileSystemDialogState extends State<FileSystemDialog> {
  bool _gridView = true, _notes = false;
  late DocumentFileSystem _fileSystem;
  final TextEditingController _pathController =
      TextEditingController(text: '/');
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _fileSystem =
        context.read<SettingsCubit>().state.getDefaultDocumentFileSystem();
    super.initState();
  }

  Future<List<AppDocumentEntity>> _loadDocuments() async {
    var documents = await _fileSystem
        .getAsset(_pathController.text)
        .then<List<AppDocumentEntity>>((value) => (value is AppDocumentDirectory
            ? value.assets
            : value is AppDocumentFile
                ? [value]
                : []));
    // Filter by _searchController.text
    if (_searchController.text.isNotEmpty) {
      documents = documents
          .where((element) =>
              element.pathWithLeadingSlash
                  .substring(element.pathWithLeadingSlash.lastIndexOf('/') + 1)
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (element is AppDocumentFile
                  ? element.fileName
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase())
                  : false))
          .toList();
    }
    return documents;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
          child: Column(
            children: [
              Header(
                  title: Text(AppLocalizations.of(context).open),
                  leading: IconButton(
                    icon: const PhosphorIcon(PhosphorIconsLight.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => setState(() {}),
                      icon:
                          const PhosphorIcon(PhosphorIconsLight.arrowClockwise),
                    ),
                    IconButton(
                        icon: PhosphorIcon(_gridView
                            ? PhosphorIconsLight.list
                            : PhosphorIconsLight.gridFour),
                        onPressed: () =>
                            setState(() => _gridView = !_gridView)),
                    IconButton(
                      tooltip: AppLocalizations.of(context).create,
                      icon: const PhosphorIcon(PhosphorIconsLight.plus),
                      onPressed: () async {
                        await showModalBottomSheet<ThemeMode>(
                            context: context,
                            constraints: const BoxConstraints(maxWidth: 640),
                            builder: (context) {
                              return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: ListView(shrinkWrap: true, children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 20),
                                      child: Text(
                                        AppLocalizations.of(context).create,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    ListTile(
                                        title: Text(
                                            AppLocalizations.of(context).file),
                                        leading: const PhosphorIcon(
                                            PhosphorIconsLight.file),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _createAsset();
                                        }),
                                    ListTile(
                                        title: Text(AppLocalizations.of(context)
                                            .folder),
                                        leading: const PhosphorIcon(
                                            PhosphorIconsLight.folder),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _createAsset(isFolder: true);
                                        }),
                                    const SizedBox(height: 32),
                                  ]));
                            });
                      },
                    ),
                  ]),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      var isMobile = constraints.maxWidth < 600;
                      var pathInput = Row(
                        children: [
                          RemoteButton(
                            currentRemote: _fileSystem.remote?.identifier ?? '',
                            onChanged: (value) {
                              _pathController.text = '/';
                              _fileSystem = DocumentFileSystem.fromPlatform(
                                  remote: value);
                              setState(() {});
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (value) async {
                                  _openAsset(
                                      await _fileSystem.getAsset(value) ??
                                          await _fileSystem.getRootDirectory());
                                },
                                controller: _pathController,
                              ),
                            ),
                          ),
                          IconButton(
                            icon:
                                const PhosphorIcon(PhosphorIconsLight.arrowUp),
                            onPressed: () {
                              var path = _pathController.text;
                              if (path.isNotEmpty && path != '/') {
                                var index = path.lastIndexOf('/');
                                if (index != -1) {
                                  _pathController.text =
                                      path.substring(0, index);
                                  if (_pathController.text.isEmpty) {
                                    _pathController.text = '/';
                                  }
                                  setState(() {});
                                }
                              }
                            },
                          ),
                        ],
                      );
                      var searchInput = Row(children: [
                        if (!kIsWeb)
                          IconButton(
                            onPressed: () => setState(() => _notes = !_notes),
                            icon: _notes
                                ? const PhosphorIcon(PhosphorIconsFill.note)
                                : const PhosphorIcon(PhosphorIconsLight.note),
                          ),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 300),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                decoration: const InputDecoration(
                                  filled: true,
                                  prefixIcon: PhosphorIcon(
                                      PhosphorIconsLight.magnifyingGlass),
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                                controller: _searchController,
                              ),
                            ),
                          ),
                        ),
                        if (_fileSystem.remote != null) const SyncButton(),
                      ]);
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  pathInput,
                                  searchInput,
                                ],
                              )
                            : SizedBox(
                                height: 50,
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Flexible(
                                        flex: 5,
                                        child: pathInput,
                                      ),
                                      Flexible(
                                        flex: 2,
                                        child: searchInput,
                                      ),
                                    ]),
                              ),
                      );
                    }),
                    const Divider(),
                    Flexible(
                        child: FutureBuilder<List<AppDocumentEntity>>(
                            future: _loadDocuments(),
                            builder: (context, snapshot) {
                              return BlocBuilder<DocumentBloc, DocumentState>(
                                  bloc: widget.bloc,
                                  builder: (context, state) {
                                    AssetLocation? selectedPath;
                                    if (state is DocumentLoadSuccess) {
                                      selectedPath = state.location;
                                    }
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Align(
                                        alignment: Alignment.center,
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return ListView(children: [
                                        Text(
                                          AppLocalizations.of(context).error,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        Text(
                                          snapshot.error.toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ]);
                                    }
                                    var assets = snapshot.data ?? [];
                                    if (_notes) {
                                      assets = assets.where((asset) {
                                        if (asset is! AppDocumentFile) {
                                          return true;
                                        }
                                        return asset.fileType ==
                                            AssetFileType.note;
                                      }).toList();
                                    }
                                    if (!kIsWeb) {
                                      assets = assets.where((asset) {
                                        if (asset is! AppDocumentFile) {
                                          return true;
                                        }
                                        return asset.fileType != null;
                                      }).toList();
                                    }
                                    void onRefreshed() {
                                      setState(() {});
                                    }

                                    return _gridView
                                        ? FileSystemGridView(
                                            selectedPath: selectedPath,
                                            assets: assets,
                                            fileSystem: _fileSystem,
                                            onOpened: _openAsset,
                                            onRefreshed: onRefreshed,
                                          )
                                        : FileSystemListView(
                                            selectedPath: selectedPath,
                                            assets: assets,
                                            fileSystem: _fileSystem,
                                            onOpened: _openAsset,
                                            onRefreshed: onRefreshed,
                                          );
                                  });
                            })),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAsset({bool isFolder = false}) async {
    var path = _pathController.text;
    if (path == '/') {
      path = '';
    }
    var success = await showDialog<bool>(
            context: context,
            builder: (context) => FileSystemAssetCreateDialog(
                isFolder: isFolder, path: path, fileSystem: _fileSystem)) ??
        false;
    if (success) {
      setState(() {});
    }
  }

  void _openAsset(AppDocumentEntity asset) {
    if (asset is AppDocumentFile) {
      final remote = _fileSystem.remote;
      final state = widget.bloc.state;
      AssetLocation? lastLocation;
      if (state is DocumentLoadSuccess) lastLocation = state.location;
      if (lastLocation == asset.location) return;
      if (remote != null) {
        GoRouter.of(context).push(
            '/remote/${Uri.encodeComponent(remote.identifier)}/${Uri.encodeComponent(asset.pathWithoutLeadingSlash)}',
            extra: asset.data);
      } else {
        GoRouter.of(context).push(
            '/local/${Uri.encodeComponent(asset.pathWithoutLeadingSlash)}',
            extra: asset.data);
      }
    } else {
      _pathController.text = asset.pathWithLeadingSlash;
      setState(() {});
    }
  }
}
