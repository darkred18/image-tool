import 'dart:io';
import 'dart:isolate';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

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

  /// 💾 편집된 이미지를 실제 스마트폰 갤러리(사진첩)로 내보내는 메서드
  static Future<void> saveToSystemGallery({required String imagePath}) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception("저장할 파일이 존재하지 않습니다.");
      }

      // 갤러리에 접근 가능한 권한이 있는지 먼저 체크 (gal 패키지 기능)
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        // 권한 요청
        await Gal.requestAccess();
      }

      // 🚀 실제 기기의 갤러리에 파일 저장
      // 앨범 이름을 지정하여 '유화레퍼런스' 같은 전용 폴더를 만들 수도 있습니다.
      await Gal.putImage(file.path, album: 'OilPaintingReference');

      debugPrint("갤러리 저장 완료: ${file.path}");
    } catch (e) {
      debugPrint("갤러리 저장 중 오류 발생: $e");
      rethrow;
    }
  }

  // 🚀 overwrite 매개변수를 없애고, 항상 새 파일로 저장되도록 단순화
  static Future<String> save({
    required String previewPath,
    required String originalPath,
  }) async {
    final file = File(originalPath);
    final dir = file.parent.path;
    final name = file.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    final stem = dot != -1 ? name.substring(0, dot) : name;
    final ext = dot != -1 ? name.substring(dot) : '.jpg';

    // 1. 매번 겹치지 않는 고유한 새 파일 경로 생성 (예: image_edited_1718293812.jpg)
    final outPath =
        '$dir/${stem}_edited_${DateTime.now().millisecondsSinceEpoch}$ext';

    // 2. 임시 파일(previewPath)을 새 파일 경로(outPath)로 복사
    await File(previewPath).copy(outPath);

    // 3. ⭐️ 갤러리에는 방금 새로 만든 '새 패스(outPath)'를 전달하여 저장!
    // 이렇게 하면 OS 갤러리 시스템이 중복이나 캐시 문제 없이 새 사진으로 정상 등록합니다.
    await saveToSystemGallery(imagePath: outPath);

    // 4. 새로 저장된 로컬 파일 경로를 반환
    return outPath;
  }

  // /// 기존 프로젝트 구조의 save 메서드 (원한다면 갤러리 저장 로직을 결합할 수 있습니다)
  // static Future<String> save({
  //   required String previewPath,
  //   required String originalPath,
  //   required bool overwrite,
  // }) async {
  //   if (overwrite) {
  //     await File(previewPath).copy(originalPath);
  //     await File(previewPath).delete();

  //     // [옵션] 덮어쓰기 완료 후 갤러리에도 즉시 동기화하고 싶다면 호출
  //     // await saveToSystemGallery(imagePath: originalPath);

  //     return originalPath;
  //   } else {
  //     // 새로운 파일명 생성 로직 (기존 코드)
  //     final file = File(originalPath);
  //     final dir = file.parent.path;
  //     final name = file.uri.pathSegments.last;
  //     final dot = name.lastIndexOf('.');
  //     final stem = dot != -1 ? name.substring(0, dot) : name;
  //     final ext = dot != -1 ? name.substring(dot) : '.jpg';

  //     final outPath =
  //         '$dir/${stem}_edited_${DateTime.now().millisecondsSinceEpoch}$ext';
  //     await File(previewPath).copy(outPath);

  //     // 🚀 [필수] 새 이름으로 저장된 파일을 갤러리로 전송
  //     await saveToSystemGallery(imagePath: outPath);

  //     return outPath;
  //   }
  // }
}
