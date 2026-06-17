import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:dartcv4/dartcv.dart' as cv;

/// 이 파일 하나로 [원근 크롭]의 UI, 상태, OpenCV 연동을 모두 끝냅니다.
class PerspectiveCropTool extends StatefulWidget {
  final String imagePath;
  final Size imageSize; // 렌더링된 이미지 크기
  final VoidCallback onComplete; // 크롭 완료 후 콜백

  const PerspectiveCropTool({
    super.key,
    required this.imagePath,
    required this.imageSize,
    required this.onComplete,
  });

  @override
  State<PerspectiveCropTool> createState() => _PerspectiveCropToolState();
}

class _PerspectiveCropToolState extends State<PerspectiveCropTool> {
  // 1. 상태 데이터 (기존 Mixin에 있던 데이터를 여기로 흡수)
  List<Offset> _points = [];
  String? _previewCropPath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initDefaultPoints();
  }

  // 초기 꼭짓점 설정
  void _initDefaultPoints() {
    final w = widget.imageSize.width;
    final h = widget.imageSize.height;
    const margin = 20.0;
    _points = [
      Offset(margin, margin),
      Offset(w - margin, margin),
      Offset(w - margin, h - margin),
      Offset(margin, h - margin),
    ];
  }

  // 2. OpenCV 비즈니스 로직 (기존 Service 내용을 내부 메서드로 흡수)
  Future<void> _processPerspectiveTransform() async {
    setState(() => _isProcessing = true);

    final imagePath = widget.imagePath;
    final imageWidgetSize = widget.imageSize;
    final points = _points;

    final dir = File(imagePath).parent.path;
    final outPath =
        '$dir/crop_preview_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      // 무거운 OpenCV 연동은 Isolate 백그라운드로 처리
      final resultPath = await Isolate.run(() {
        final src = cv.imread(imagePath);
        final imgW = src.cols.toDouble();
        final imgH = src.rows.toDouble();

        final scaleX = imgW / imageWidgetSize.width;
        final scaleY = imgH / imageWidgetSize.height;

        final srcPts = cv.VecPoint.fromList(
          points
              .map(
                (o) =>
                    cv.Point((o.dx * scaleX).round(), (o.dy * scaleY).round()),
              )
              .toList(),
        );

        final outW = ((points[1].dx - points[0].dx) * scaleX).abs();
        final outH = ((points[3].dy - points[0].dy) * scaleY).abs();

        final dstPts = cv.VecPoint.fromList([
          cv.Point(0, 0),
          cv.Point(outW.round(), 0),
          cv.Point(outW.round(), outH.round()),
          cv.Point(0, outH.round()),
        ]);

        final M = cv.getPerspectiveTransform(srcPts, dstPts);
        final dst = cv.warpPerspective(src, M, (outW.toInt(), outH.toInt()));

        cv.imwrite(outPath, dst);

        src.dispose();
        dst.dispose();
        M.dispose();

        return outPath;
      });

      setState(() {
        _previewCropPath = resultPath;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      // 에러 처리 로직 필요 시 추가
    }
  }

  // 3. UI 렌더링 (기존 Overlay UI와 핸들 조작을 결합)
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 선 그리기
        CustomPaint(
          size: widget.imageSize,
          painter: _PolygonLinePainter(points: _points),
        ),
        // 드래그 가능한 꼭짓점 핸들 4개
        ...List.generate(4, (i) => _buildHandle(i)),

        // 처리 중일 때 띄울 인디케이터 (선택 사항)
        if (_isProcessing) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildHandle(int index) {
    const handleSize = 28.0;
    const half = handleSize / 2;

    return Positioned(
      left: _points[index].dx - half,
      top: _points[index].dy - half,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _points[index] += details.delta;
            _previewCropPath = null; // 좌표 바뀌면 이전 미리보기 초기화
          });
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

// 4. 전용 Painter (외부 유출 없이 이 파일 내부에서만 사용)
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
