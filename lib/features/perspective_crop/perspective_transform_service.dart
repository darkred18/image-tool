import 'dart:io';
import 'dart:isolate';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';

class PerspectiveTransformService {
  static Future<String> transform({
    required String imagePath,
    required List<Offset> points,
    required Size imageWidgetSize,
  }) async {
    final dir = File(imagePath).parent.path;
    final outPath =
        '$dir/crop_preview_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Isolate.run(() {
      final src = cv.imread(imagePath);
      final imgW = src.cols.toDouble();
      final imgH = src.rows.toDouble();

      final scaleX = imgW / imageWidgetSize.width;
      final scaleY = imgH / imageWidgetSize.height;

      final srcPts = cv.VecPoint.fromList(
        points
            .map(
              (o) => cv.Point((o.dx * scaleX).round(), (o.dy * scaleY).round()),
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
    });

    return outPath;
  }

  static Future<String> save({
    required String previewPath,
    required String originalPath,
    required bool overwrite,
  }) async {
    if (overwrite) {
      await File(previewPath).copy(originalPath);
      await File(previewPath).delete();
      return originalPath;
    } else {
      final file = File(originalPath);
      final dir = file.parent.path;
      final name = file.uri.pathSegments.last;
      final dot = name.lastIndexOf('.');
      final stem = dot != -1 ? name.substring(0, dot) : name;
      final ext = dot != -1 ? name.substring(dot) : '';
      final newPath =
          '$dir/${stem}_crop_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(previewPath).copy(newPath);
      await File(previewPath).delete();
      return newPath;
    }
  }
}
