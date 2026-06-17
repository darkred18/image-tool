import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';

class PerspectiveCropOverlay extends StatefulWidget {
  final EditPageController controller;
  final Size imageSize;

  const PerspectiveCropOverlay({
    super.key,
    required this.controller,
    required this.imageSize,
  });

  @override
  State<PerspectiveCropOverlay> createState() => _PerspectiveCropOverlayState();
}

class _PerspectiveCropOverlayState extends State<PerspectiveCropOverlay> {
  List<Offset> _defaultPoints() {
    final w = widget.imageSize.width;
    final h = widget.imageSize.height;
    const margin = 20.0;
    return [
      Offset(margin, margin),
      Offset(w - margin, margin),
      Offset(w - margin, h - margin),
      Offset(margin, h - margin),
    ];
  }

  List<Offset> get _points {
    return widget.controller.getCropPoints(widget.controller.currentIndex) ??
        _defaultPoints();
  }

  void _updatePoints(List<Offset> points) {
    widget.controller.updateCropPoints(widget.controller.currentIndex, points);
  }

  @override
  void initState() {
    super.initState();
    // 처음 진입 시 기본값 저장
    if (widget.controller.getCropPoints(widget.controller.currentIndex) ==
        null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updatePoints(_defaultPoints());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          // size: widget.imageSize,
          painter: _PolygonLinePainter(points: points),
        ),
        ...List.generate(4, (i) => _buildHandle(i, points)),
      ],
    );
  }

  Widget _buildHandle(int index, List<Offset> points) {
    const handleSize = 28.0;
    const half = handleSize / 2;

    return Positioned(
      left: points[index].dx - half,
      top: points[index].dy - half,
      child: GestureDetector(
        onPanUpdate: (details) {
          final updated = List<Offset>.from(points);
          final newPos = updated[index] + details.delta;

          updated[index] = newPos;
          _updatePoints(updated);
        },
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _PolygonLinePainter extends CustomPainter {
  final List<Offset> points;
  _PolygonLinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PolygonLinePainter old) => true;
}
