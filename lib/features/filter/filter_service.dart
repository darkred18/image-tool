import 'dart:io';
import 'dart:isolate';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:image_tools/controller/providers.dart';

class FilterService {
  static Future<String> apply({
    required String imagePath,
    required FilterType? filterType,
    required double strength,
  }) async {
    if (filterType == null) return imagePath;
    final dir = File(imagePath).parent.path;
    final outPath =
        '$dir/filter_preview_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Isolate.run(() {
      final src = cv.imread(imagePath);

      cv.Mat result;

      switch (filterType) {
        case FilterType.edge:
          // 스케치 느낌 엣지 강조
          final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
          final blurred = cv.gaussianBlur(gray, (5, 5), 0);
          final thresh = (strength * 200).toInt().clamp(10, 200);
          final edges = cv.canny(
            blurred,
            thresh.toDouble(),
            (thresh * 2).toDouble(),
          );
          final inverted = cv.bitwiseNOT(edges);
          result = cv.cvtColor(inverted, cv.COLOR_GRAY2BGR);

        // case FilterType.simplify:
        //   // K-Means 색상 단순화
        //   final k = (2 + strength * 8).toInt().clamp(2, 10);
        //   final data = src.reshape(1, src.rows * src.cols);
        //   final floatData = data.convertTo(cv.MatType.CV_32FC3);
        //   final labels = cv.Mat.empty();
        //   final centers = cv.Mat.empty();
        //   cv.kmeans(
        //     floatData,
        //     k,
        //     labels,
        //     (cv.TERM_COUNT + cv.TERM_EPS, 10, 1.0),
        //     3,
        //     cv.KMEANS_RANDOM_CENTERS,
        //     centers: centers,
        //   );
        //   // 각 픽셀을 클러스터 중심값으로 교체
        //   final resultData = cv.Mat.zeros(
        //     src.rows * src.cols,
        //     1,
        //     cv.MatType.CV_8UC3,
        //   );
        //   for (int i = 0; i < labels.rows; i++) {
        //     final label = labels.at<int>(i, 0);
        //     final b = centers.at<double>(label, 0).round().clamp(0, 255);
        //     final g = centers.at<double>(label, 1).round().clamp(0, 255);
        //     final r = centers.at<double>(label, 2).round().clamp(0, 255);
        //     resultData.set<int>(i, 0, b);
        //     resultData.set<int>(i, 1, g);
        //     resultData.set<int>(i, 2, r);
        //   }
        //   result = resultData.reshape(3, src.rows);

        // 큰변화 없음
        // case FilterType.simplify:
        //   final d = 9;
        //   final sigma = 50 + strength * 50;
        //   var temp = cv.bilateralFilter(src, d, sigma, sigma);
        //   // 2~3회 반복할수록 색면이 더 단순해짐
        //   final iterations = (1 + strength * 2).toInt();
        //   for (int i = 0; i < iterations; i++) {
        //     final next = cv.bilateralFilter(temp, d, sigma, sigma);
        //     temp.dispose();
        //     temp = next;
        //   }
        //   result = temp;

        case FilterType.simplify:
          final k = (2 + strength * 6).toInt().clamp(2, 8);
          final blurSize = (3 + strength * 10).toInt();
          final blurOdd = blurSize % 2 == 0 ? blurSize + 1 : blurSize;
          final blurred = cv.gaussianBlur(src, (blurOdd, blurOdd), 0);
          final data = blurred.reshape(1, src.rows * src.cols);
          final floatData = data.convertTo(cv.MatType.CV_32FC3);
          final labels = cv.Mat.empty();
          final centers = cv.Mat.empty();
          cv.kmeans(
            floatData,
            k,
            labels,
            (cv.TERM_COUNT + cv.TERM_EPS, 10, 1.0),
            3,
            cv.KMEANS_RANDOM_CENTERS,
            centers: centers,
          );
          final centersByte = centers.convertTo(cv.MatType.CV_8UC3);
          final labelsReshaped = labels.reshape(1, src.rows);
          result = cv.Mat.zeros(src.rows, src.cols, cv.MatType.CV_8UC3);
          for (int r = 0; r < src.rows; r++) {
            for (int c = 0; c < src.cols; c++) {
              final label = labelsReshaped.at<int>(r, c);
              result.set<cv.Vec3b>(r, c, centersByte.at<cv.Vec3b>(label, 0));
            }
          }
          blurred.dispose();
          data.dispose();
          floatData.dispose();
          labels.dispose();
          centers.dispose();
          centersByte.dispose();
          labelsReshaped.dispose();

        case FilterType.contrast:
          // 명암 강조
          final alpha = 1.0 + strength * 2.0; // 1.0~3.0
          final beta = -strength * 50; // 0~-50
          result = cv.convertScaleAbs(src, alpha: alpha, beta: beta);

        case FilterType.blur:
          // Bilateral 블러 (색면 단순화)
          final d = (5 + strength * 20).toInt().clamp(5, 25);
          final sigma = 50 + strength * 100;
          result = cv.bilateralFilter(src, d, sigma, sigma);
      }

      cv.imwrite(outPath, result);
      src.dispose();
      result.dispose();
    });

    return outPath;
  }

  static Future<void> deletePreview(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
