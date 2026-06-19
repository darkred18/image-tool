import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/grid/grid_controller.dart';

class GridOverlay extends ConsumerWidget {
  final Size imageSize;

  const GridOverlay({super.key, required this.imageSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(gridProvider);
    return IgnorePointer(
      child: CustomPaint(size: imageSize, painter: _GridPainter(grid)),
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridState grid;

  _GridPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = grid.gridColor.withAlpha(180)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    void drawV(double dx) {
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), shadowPaint);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
    }

    void drawH(double dy) {
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), shadowPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }

    drawH(centerY);
    drawV(centerX);

    switch (grid.selectedGridType) {
      case GridType.square:
        final int divisions = grid.squareDivisions > 0
            ? grid.squareDivisions
            : 4;
        final double cellSize = grid.squareBasis == SquareBasis.width
            ? size.width / (divisions * 2)
            : size.height / (divisions * 2);

        if (cellSize > 0) {
          for (
            double dx = centerX + cellSize;
            dx < size.width;
            dx += cellSize
          ) {
            drawV(dx);
          }
          for (double dx = centerX - cellSize; dx > 0; dx -= cellSize) {
            drawV(dx);
          }
          for (
            double dy = centerY + cellSize;
            dy < size.height;
            dy += cellSize
          ) {
            drawH(dy);
          }
          for (double dy = centerY - cellSize; dy > 0; dy -= cellSize) {
            drawH(dy);
          }
        }
        break;

      case GridType.horizontal:
        final int hLines = grid.horizontalDivisions;
        final int vLines = grid.verticalDivisions;
        if (hLines > 0) {
          final double gapY = centerY / hLines;
          for (int i = 1; i <= hLines; i++) {
            final double offset = gapY * i;
            drawH(centerY - offset);
            drawH(centerY + offset);
          }
          final double gapX = centerX / vLines;
          for (int i = 1; i <= vLines; i++) {
            final double offset = gapX * i;
            drawV(centerX - offset);
            drawV(centerX + offset);
          }
        }
        break;

      case GridType.vertical:
        final int hLines = grid.horizontalDivisions;
        final int vLines = grid.verticalDivisions;
        if (vLines > 0) {
          final double gapX = centerX / vLines;
          for (int i = 1; i <= vLines; i++) {
            final double offset = gapX * i;
            drawV(centerX - offset);
            drawV(centerX + offset);
          }
        }
        final double gapY = centerY / hLines;
        for (int i = 1; i <= hLines; i++) {
          final double offset = gapY * i;
          drawH(centerY - offset);
          drawH(centerY + offset);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.grid != grid;
}
