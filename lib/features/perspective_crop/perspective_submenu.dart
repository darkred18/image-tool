import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/perspective_crop/perspective_transform_service.dart';

class PerspectiveSubMenu extends ConsumerWidget {
  const PerspectiveSubMenu({super.key});

  Future<void> _runTransformAndSave(WidgetRef ref, BuildContext context) async {
    final index = ref.read(currentIndexProvider);
    final cropState = ref.read(perspectiveCropProvider);
    final points = cropState.cropPoints[index];
    final imageWidgetSize = ref.read(currentImageWidgetSizeProvider);
    final images = ref.read(imagesProvider);

    if (points == null || imageWidgetSize == null) return;

    ref.read(perspectiveCropProvider.notifier).setProcessing(true);
    try {
      // 1. 원근 변환
      final previewPath = await PerspectiveTransformService.transform(
        imagePath: images[index],
        points: points,
        imageWidgetSize: imageWidgetSize,
      );

      // 2. 즉시 저장
      final savedPath = await PerspectiveTransformService.save(
        previewPath: previewPath,
        originalPath: images[index],
      );

      // 3. 현재 이미지를 저장된 파일로 교체
      final updatedImages = List<String>.from(images);
      updatedImages[index] = savedPath;
      ref.read(imagesProvider.notifier).state = updatedImages;

      // 4. 크롭 상태 초기화 (새 이미지 기준으로 다시 시작)
      ref.read(perspectiveCropProvider.notifier).reset(index);

      // 5. 툴 닫기
      ref.read(activeToolProvider.notifier).state = EditTool.none;

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 새 파일로 저장되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('변환 실패: $e')));
        debugPrint('Perspective transform error: $e');
      }
    } finally {
      ref.read(perspectiveCropProvider.notifier).setProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(perspectiveCropProvider).isProcessing;

    return SubMenuShell(
      children: [
        ElevatedButton.icon(
          onPressed: isProcessing
              ? null
              : () => _runTransformAndSave(ref, context),
          icon: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.crop_rotate, size: 18),
          label: Text(isProcessing ? '처리 중...' : '변환 및 저장'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }
}
