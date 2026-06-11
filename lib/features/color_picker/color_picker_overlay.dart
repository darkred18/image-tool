import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/color_picker/color_alalysis_service.dart';

class ColorPickerOverlay extends StatefulWidget {
  final EditPageController controller;
  final String imageUrl;

  const ColorPickerOverlay({
    super.key,
    required this.controller,
    required this.imageUrl,
  });

  @override
  State<ColorPickerOverlay> createState() => _ColorPickerOverlayState();
}

class _ColorPickerOverlayState extends State<ColorPickerOverlay> {
  Offset? _boxCenter;
  ui.Image? _uiImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imageUrl).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _uiImage = frame.image);
    }
  }

  /// 박스 영역을 ui.Image에서 크롭해서 프리뷰로 저장
  Future<void> _updatePreview(Offset boxCenter) async {
    final image = _uiImage;
    final imageWidgetSize = widget.controller.imageWidgetSize;
    if (image == null || imageWidgetSize == null) return;

    final boxSize = widget.controller.colorPickerBoxSize;
    final scaleX = image.width / imageWidgetSize.width;
    final scaleY = image.height / imageWidgetSize.height;

    final srcX = ((boxCenter.dx - boxSize / 2) * scaleX).round().clamp(
      0,
      image.width - 1,
    );
    final srcY = ((boxCenter.dy - boxSize / 2) * scaleY).round().clamp(
      0,
      image.height - 1,
    );
    final srcW = (boxSize * scaleX).round().clamp(1, image.width - srcX);
    final srcH = (boxSize * scaleY).round().clamp(1, image.height - srcY);

    // Picture recorder로 해당 영역만 크롭
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        srcX.toDouble(),
        srcY.toDouble(),
        srcW.toDouble(),
        srcH.toDouble(),
      ),
      Rect.fromLTWH(0, 0, 80, 80),
      Paint(),
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(80, 80);

    widget.controller.updatePreviewImage(cropped);
  }

  Future<void> _analyze(Offset boxCenter) async {
    if (widget.controller.imageWidgetSize == null) return;

    // 프리뷰 업데이트
    await _updatePreview(boxCenter);

    widget.controller.setAnalyzing(true);
    try {
      final mixes = await ColorAnalysisService.analyze(
        imagePath: widget.imageUrl,
        boxCenter: boxCenter,
        boxSize: widget.controller.colorPickerBoxSize,
        imageWidgetSize: widget.controller.imageWidgetSize!,
      );
      widget.controller.setPaintMixes(mixes);
    } catch (e) {
      debugPrint('Color analysis error: $e');
    } finally {
      widget.controller.setAnalyzing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = widget.controller.colorPickerBoxSize;
        final half = boxSize / 2;

        _boxCenter ??= Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );

        final clampedCenter = Offset(
          _boxCenter!.dx.clamp(half, constraints.maxWidth - half),
          _boxCenter!.dy.clamp(half, constraints.maxHeight - half),
        );

        return Stack(
          children: [
            Positioned(
              left: clampedCenter.dx - half,
              top: clampedCenter.dy - half,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _boxCenter = Offset(
                      (_boxCenter!.dx + details.delta.dx).clamp(
                        half,
                        constraints.maxWidth - half,
                      ),
                      (_boxCenter!.dy + details.delta.dy).clamp(
                        half,
                        constraints.maxHeight - half,
                      ),
                    );
                  });
                },
                onPanEnd: (_) => _analyze(clampedCenter),
                child: CustomPaint(
                  size: Size(boxSize, boxSize),
                  painter: _SampleBoxPainter(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SampleBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final crossPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      crossPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SampleBoxPainter old) => false;
}
