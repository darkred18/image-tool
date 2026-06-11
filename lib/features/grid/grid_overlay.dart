import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/grid/grid_controller.dart';

class GridOverlay extends StatelessWidget {
  final EditPageController controller;
  final Size imageSize;

  const GridOverlay({
    super.key,
    required this.controller,
    required this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: imageSize, painter: _GridPainter(controller)),
    );
  }
}

class _GridPainter extends CustomPainter {
  final EditPageController controller;

  _GridPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(60)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = controller.gridColor.withAlpha(180)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    void drawV(double dx) {
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), shadowPaint);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
    }

    void drawH(double dy) {
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), shadowPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }

    switch (controller.selectedGridType) {
      // ── 정방형: 기준 축 셀 크기로 정사각형 격자 ──────────────────
      case GridType.square:
        final int divisions = controller.squareDivisions;
        final double cellSize = controller.squareBasis == SquareBasis.width
            ? size.width / divisions
            : size.height / divisions;

        // 세로선
        for (double dx = cellSize; dx < size.width - 0.5; dx += cellSize) {
          drawV(dx);
        }
        // 가로선
        for (double dy = cellSize; dy < size.height - 0.5; dy += cellSize) {
          drawH(dy);
        }

      // ── 가로만: 수평 분할선만 ─────────────────────────────────────
      case GridType.horizontal:
        final int divisions = controller.horizontalDivisions;
        final double cellHeight = size.height / divisions;
        for (int i = 1; i < divisions; i++) {
          drawH(cellHeight * i);
        }

      // ── 세로만: 수직 분할선만 ─────────────────────────────────────
      case GridType.vertical:
        final int divisions = controller.verticalDivisions;
        final double cellWidth = size.width / divisions;
        for (int i = 1; i < divisions; i++) {
          drawV(cellWidth * i);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}
