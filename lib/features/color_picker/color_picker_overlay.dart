import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';

import 'package:image_tools/features/color_picker/color_alalysis_service.dart';

class ColorPickerOverlay extends ConsumerStatefulWidget {
  final Size imageSize;
  final String imageUrl;

  const ColorPickerOverlay({
    super.key,

    required this.imageSize,
    required this.imageUrl,
  });

  @override
  ConsumerState<ColorPickerOverlay> createState() => _ColorPickerOverlayState();
}

class _ColorPickerOverlayState extends ConsumerState<ColorPickerOverlay> {
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
    final imageWidgetSize = ref.read(currentImageWidgetSizeProvider);
    if (image == null || imageWidgetSize == null) return;

    final boxSize = ref.read(colorPickerProvider).boxSize;
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

    ref.read(colorPickerProvider.notifier).updatePreviewImage(cropped);
  }

  Future<void> _analyze(Offset boxCenter) async {
    final imageWidgetSize = ref.read(currentImageWidgetSizeProvider);
    if (imageWidgetSize == null) return;

    await _updatePreview(boxCenter);

    final notifier = ref.read(colorPickerProvider.notifier);
    notifier.setAnalyzing(true);
    try {
      final mixes = await ColorAnalysisService.analyze(
        imagePath: widget.imageUrl,
        boxCenter: boxCenter,
        boxSize: ref.read(colorPickerProvider).boxSize,
        imageWidgetSize: imageWidgetSize,
      );
      notifier.setPaintMixes(mixes);
    } catch (e) {
      debugPrint('Color analysis error: $e');
    } finally {
      notifier.setAnalyzing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 부모(SizedBox)가 정해준 명확한 이미지 사이즈를 기준점으로 삼습니다.
    final double maxWidth = widget.imageSize.width;
    final double maxHeight = widget.imageSize.height;

    final boxSize = ref.watch(colorPickerProvider).boxSize;
    final half = boxSize / 2;

    // 최초 진입 시, 화면 중앙이 아니라 '이미지의 정중앙'에 박스를 배치합니다.
    _boxCenter ??= Offset(maxWidth / 2, maxHeight / 2);

    final clampedCenter = Offset(
      _boxCenter!.dx.clamp(half, maxWidth - half),
      _boxCenter!.dy.clamp(half, maxHeight - half),
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
                    maxWidth - half,
                  ),
                  (_boxCenter!.dy + details.delta.dy).clamp(
                    half,
                    maxHeight - half,
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
