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
      // 🎯 [핵심 복구] controller를 다시 주입하여 변경 사항을 감지하도록 합니다.
      child: CustomPaint(size: imageSize, painter: _GridPainter(controller)),
    );
  }
}

class _GridPainter extends CustomPainter {
  final EditPageController controller;

  // super(repaint: controller)로 UI 슬라이더 및 타입 변경 시 즉각 반응하도록 바인딩
  _GridPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. 선 가독성을 위한 배경 그림자 펜
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 2. 메인 그리드 펜
    final linePaint = Paint()
      ..color = controller.gridColor.withAlpha(180)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 공통 선 그리기 헬퍼 함수들
    void drawV(double dx) {
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), shadowPaint);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
    }

    void drawH(double dy) {
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), shadowPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }

    drawH(centerY); // 중앙선 고정
    drawV(centerX); // 중앙선 고정
    // ── 🎯 [핵심] 사용자가 선택한 그리드 타입에 따라 분기 처리 ──
    switch (controller.selectedGridType) {
      // 1️⃣ 정방형 바둑판 격자: 정중앙 기준으로 사방으로 확장
      case GridType.square:
        final int divisions = controller.squareDivisions > 0
            ? controller.squareDivisions
            : 4;
        final double cellSize = controller.squareBasis == SquareBasis.width
            ? size.width / (divisions * 2)
            : size.height / (divisions * 2);

        if (cellSize > 0) {
          // 중앙 메인 십자선 고정
          // drawH(centerY);
          // drawV(centerX);

          // 세로선들을 중앙에서 좌우로 확장하며 그리기
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

          // 가로선들을 중앙에서 상하로 확장하며 그리기
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

      // 2️⃣ 가로선만: 정중앙 가로선 기준, 상하 대칭 확장
      case GridType.horizontal:
        final int hLines = controller.horizontalDivisions;
        final int vLines = controller.verticalDivisions;
        if (hLines > 0) {
          final double gapY = centerY / (hLines);
          for (int i = 1; i <= hLines; i++) {
            final double offset = gapY * i;
            drawH(centerY - offset);
            drawH(centerY + offset);
          }
          final double gapX = centerX / (vLines);
          for (int i = 1; i <= vLines; i++) {
            final double offset = gapX * i;
            drawV(centerX - offset);
            drawV(centerX + offset);
          }
        }
        break;

      // 3️⃣ 세로선만: 정중앙 세로선 기준, 좌우 대칭 확장
      case GridType.vertical:
        // drawV(centerX); // 중앙선 고정
        // drawH(centerY); // 중앙선 고정
        final int hLines = controller.horizontalDivisions;
        final int vLines = controller.verticalDivisions;
        if (vLines > 0) {
          final double gapX = centerX / (vLines);
          for (int i = 1; i <= vLines; i++) {
            final double offset = gapX * i;
            drawV(centerX - offset);
            drawV(centerX + offset);
          }
        }
        final double gapY = centerY / (hLines);
        for (int i = 1; i <= hLines; i++) {
          final double offset = gapY * i;
          drawH(centerY - offset);
          drawH(centerY + offset);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}
