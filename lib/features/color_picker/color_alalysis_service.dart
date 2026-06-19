import 'dart:isolate';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';

// 유화 물감 팔레트 데이터
const List<Map<String, dynamic>> _oilPaintPalette = [
  {'name': 'Titanium White', 'r': 255, 'g': 255, 'b': 255},
  {'name': 'Ivory Black', 'r': 30, 'g': 30, 'b': 30},
  {'name': 'Burnt Umber', 'r': 138, 'g': 51, 'b': 36},
  {'name': 'Raw Umber', 'r': 115, 'g': 74, 'b': 18},
  {'name': 'Burnt Sienna', 'r': 233, 'g': 116, 'b': 81},
  {'name': 'Yellow Ochre', 'r': 204, 'g': 153, 'b': 51},
  {'name': 'Cadmium Yellow', 'r': 255, 'g': 215, 'b': 0},
  {'name': 'Cadmium Red', 'r': 220, 'g': 36, 'b': 36},
  {'name': 'Alizarin Crimson', 'r': 227, 'g': 38, 'b': 54},
  {'name': 'Ultramarine', 'r': 18, 'g': 10, 'b': 143},
  {'name': 'Cobalt Blue', 'r': 0, 'g': 71, 'b': 171},
  {'name': 'Cerulean Blue', 'r': 42, 'g': 82, 'b': 190},
  {'name': 'Viridian', 'r': 64, 'g': 130, 'b': 109},
  {'name': 'Sap Green', 'r': 78, 'g': 125, 'b': 54},
  {'name': 'Raw Sienna', 'r': 214, 'g': 138, 'b': 89},
];

class PaintMix {
  final Color color; // 추출된 색상
  final double ratio; // 전체 대비 비율 (0~1)
  final List<PaintComponent> components; // 물감 조합

  const PaintMix({
    required this.color,
    required this.ratio,
    required this.components,
  });
}

class PaintComponent {
  final String name;
  final int percent;
  final Color color;

  const PaintComponent({
    required this.name,
    required this.percent,
    required this.color,
  });
}

class ColorAnalysisService {
  /// 이미지의 박스 영역에서 K-Means로 주요 색상 추출 후 물감 조합 반환
  static Future<List<PaintMix>> analyze({
    required String imagePath,
    required Offset boxCenter,
    required double boxSize,
    required Size imageWidgetSize,
    int k = 3, // 추출할 주요 색상 수
  }) async {
    return await Isolate.run(() {
      final src = cv.imread(imagePath);
      final imgW = src.cols.toDouble();
      final imgH = src.rows.toDouble();

      final scaleX = imgW / imageWidgetSize.width;
      final scaleY = imgH / imageWidgetSize.height;

      // 박스 영역 크롭
      final half = boxSize / 2;
      final x = ((boxCenter.dx - half) * scaleX).round().clamp(0, src.cols - 1);
      final y = ((boxCenter.dy - half) * scaleY).round().clamp(0, src.rows - 1);
      final w = (boxSize * scaleX).round().clamp(1, src.cols - x);
      final h = (boxSize * scaleY).round().clamp(1, src.rows - y);

      final roi = src.region(cv.Rect(x, y, w, h));

      // K-Means 입력 데이터 준비 (픽셀을 1행 벡터로 reshape)
      final resized = cv.resize(roi, (100, 100)); // 성능을 위해 축소
      final data = resized.reshape(1, resized.rows * resized.cols);
      final floatData = data.convertTo(cv.MatType.CV_32FC3);

      final labels = cv.Mat.empty();
      final centers = cv.Mat.empty();

      // TERM_CRITERIA_MAX_ITER=1, TERM_CRITERIA_EPS=2
      cv.kmeans(
        floatData,
        k,
        labels,
        (cv.TERM_COUNT + cv.TERM_EPS, 10, 1.0),
        3,
        cv.KMEANS_RANDOM_CENTERS,
        centers: centers,
      );

      // 각 클러스터 픽셀 수 카운트
      final counts = List<int>.filled(k, 0);
      for (int i = 0; i < labels.rows; i++) {
        counts[labels.at<int>(i, 0)]++;
      }
      final total = counts.fold(0, (a, b) => a + b);

      // 클러스터 색상 + 비율 추출
      final results = <Map<String, dynamic>>[];
      for (int i = 0; i < k; i++) {
        final b = centers.at<double>(i, 0).round().clamp(0, 255);
        final g = centers.at<double>(i, 1).round().clamp(0, 255);
        final r = centers.at<double>(i, 2).round().clamp(0, 255);
        results.add({'r': r, 'g': g, 'b': b, 'ratio': counts[i] / total});
      }

      // 비율 높은 순 정렬
      results.sort(
        (a, b) => (b['ratio'] as double).compareTo(a['ratio'] as double),
      );

      src.dispose();
      roi.dispose();
      resized.dispose();
      data.dispose();
      floatData.dispose();
      labels.dispose();
      centers.dispose();

      // 물감 조합 계산 (Isolate에서 반환 가능한 primitive 타입으로)
      return results.map((c) {
        final components = _matchPaints(c['r'], c['g'], c['b']);
        return {
          'r': c['r'],
          'g': c['g'],
          'b': c['b'],
          'ratio': c['ratio'],
          'components': components,
        };
      }).toList();
    }).then((rawList) {
      // Isolate 결과 → PaintMix 객체로 변환
      return rawList.map<PaintMix>((c) {
        return PaintMix(
          color: Color.fromRGBO(c['r'], c['g'], c['b'], 1.0),
          ratio: c['ratio'],
          components: (c['components'] as List<Map<String, dynamic>>)
              .map(
                (p) => PaintComponent(
                  name: p['name'],
                  percent: p['percent'],
                  color: Color.fromRGBO(p['r'], p['g'], p['b'], 1.0),
                ),
              )
              .toList(),
        );
      }).toList();
    });
  }

  /// 색상값에 가장 가까운 물감 조합 반환 (최대 3가지)
  static List<Map<String, dynamic>> _matchPaints(int r, int g, int b) {
    // 각 팔레트 색상과의 거리 계산
    final distances = _oilPaintPalette.map((paint) {
      final dr = r - (paint['r'] as int);
      final dg = g - (paint['g'] as int);
      final db = b - (paint['b'] as int);
      return {...paint, 'dist': dr * dr + dg * dg + db * db};
    }).toList();

    distances.sort((a, b) => (a['dist'] as int).compareTo(b['dist'] as int));

    final top = distances.take(3).toList();
    final totalDist = top.fold<int>(
      0,
      (sum, p) => sum + (p['dist'] as int) + 1,
    );

    // 거리 역수로 비율 계산 (가까울수록 비율 높음)
    final weights = top.map((p) {
      return 1.0 / ((p['dist'] as int) + 1);
    }).toList();
    final weightSum = weights.fold(0.0, (a, b) => a + b);

    return List.generate(top.length, (i) {
      final percent = ((weights[i] / weightSum) * 100).round();
      return {
        'name': top[i]['name'],
        'percent': percent,
        'r': top[i]['r'],
        'g': top[i]['g'],
        'b': top[i]['b'],
      };
    });
  }
}
