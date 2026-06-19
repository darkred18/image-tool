import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';

class PerspectiveCropOverlay extends ConsumerStatefulWidget {
  final Size imageSize;
  final int index;

  const PerspectiveCropOverlay({
    super.key,
    required this.imageSize,
    required this.index,
  });

  @override
  ConsumerState<PerspectiveCropOverlay> createState() =>
      _PerspectiveCropOverlayState();
}

class _PerspectiveCropOverlayState
    extends ConsumerState<PerspectiveCropOverlay> {
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

  @override
  void initState() {
    super.initState();
    // 처음 진입 시 기본 꼭짓점 저장
    final existing = ref.read(perspectiveCropProvider).cropPoints[widget.index];
    if (existing == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(perspectiveCropProvider.notifier)
            .updatePoints(widget.index, _defaultPoints());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final points =
        ref.watch(perspectiveCropProvider).cropPoints[widget.index] ??
        _defaultPoints();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(painter: _PolygonLinePainter(points: points)),
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
          updated[index] = updated[index] + details.delta;
          ref
              .read(perspectiveCropProvider.notifier)
              .updatePoints(widget.index, updated);
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
    if (points.length < 4) return;
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
