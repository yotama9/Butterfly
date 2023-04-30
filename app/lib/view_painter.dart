import 'package:butterfly/helpers/rect_helper.dart';
import 'package:butterfly/models/viewport.dart';
import 'package:butterfly/renderers/renderer.dart';
import 'package:butterfly_api/butterfly_api.dart';
import 'package:flutter/material.dart';

import 'cubits/transform.dart';
import 'selections/selection.dart';

class ForegroundPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final DocumentPage page;
  final List<Renderer> renderers;
  final CameraTransform transform;
  final Selection? selection;
  final Renderer<ToolState>? tool;

  ForegroundPainter(this.renderers, this.page, this.colorScheme,
      [this.transform = const CameraTransform(), this.selection, this.tool]);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(transform.size);
    canvas.translate(transform.position.dx, transform.position.dy);
    for (var element in renderers) {
      element.build(canvas, size, page, transform, colorScheme, true);
    }
    final selection = this.selection;
    if (selection is ElementSelection) {
      /*
      final minX =
          -transform.position.dx + 20 / ((transform.size - 1) / 1.5 + 1);
      final maxX = minX + size.width / transform.size - 40 / transform.size;
      final minY = -transform.position.dy + 20;
      final maxY = minY + size.height / transform.size - 40 / transform.size;
      */
      _drawSelection(canvas, selection);
    }
    if (tool != null) {
      tool!.build(canvas, size, page, transform, colorScheme, true);
    }
  }

  void _drawSelection(Canvas canvas, ElementSelection selection) {
    final rect = selection.rect;
    if (rect == null) return;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            rect.inflate(5 / transform.size), const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = colorScheme.primary
          ..strokeWidth = 5 / transform.size);
  }

  @override
  bool shouldRepaint(ForegroundPainter oldDelegate) =>
      oldDelegate.renderers != renderers ||
      oldDelegate.transform != transform ||
      oldDelegate.selection != selection ||
      oldDelegate.tool != tool;
}

class ViewPainter extends CustomPainter {
  final DocumentPage page;
  final Area? currentArea;
  final bool renderBackground, renderBaked;
  final CameraViewport cameraViewport;
  final CameraTransform transform;
  final ColorScheme? colorScheme;
  final List<String> invisibleLayers;

  const ViewPainter(
    this.page, {
    this.currentArea,
    this.invisibleLayers = const [],
    this.renderBackground = true,
    this.renderBaked = true,
    required this.cameraViewport,
    this.colorScheme,
    this.transform = const CameraTransform(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    var areaRect = currentArea?.rect;
    if (areaRect != null) {
      areaRect = Rect.fromPoints(transform.globalToLocal(areaRect.topLeft),
          transform.globalToLocal(areaRect.bottomRight));
    }
    if (areaRect != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              areaRect.inflate(5), const Radius.circular(5)),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = colorScheme?.primary ?? Colors.black
            ..strokeWidth = 5 * transform.size
            ..blendMode = BlendMode.srcOver);
      canvas.clipRect(areaRect.inflate(5));
    }
    if (renderBackground) {
      cameraViewport.background
          ?.build(canvas, size, page, transform, colorScheme);
    }
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    if (cameraViewport.bakedElements.isNotEmpty && renderBaked) {
      var image = cameraViewport.image;
      var bakedSizeDiff =
          (transform.size - cameraViewport.scale) / cameraViewport.scale;
      var pos = transform.globalToLocal(-cameraViewport.toOffset());

      // Draw our baked image, scaling it down with drawImageRect.
      if (image != null) {
        canvas.drawImageRect(
          image,
          Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
          pos & size * (1 + bakedSizeDiff),
          Paint(),
        );
      }
    }
    canvas.scale(transform.size, transform.size);
    canvas.translate(transform.position.dx, transform.position.dy);
    for (var renderer in cameraViewport.unbakedElements) {
      if (!invisibleLayers.contains(renderer.element.layer)) {
        renderer.build(canvas, size, page, transform, colorScheme, false);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ViewPainter oldDelegate) {
    final shouldRepaint = page != oldDelegate.page ||
        renderBackground != oldDelegate.renderBackground ||
        transform != oldDelegate.transform ||
        cameraViewport != oldDelegate.cameraViewport;
    return shouldRepaint;
  }
}
