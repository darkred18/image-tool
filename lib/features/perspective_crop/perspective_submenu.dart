// ============================================================
// ✂️ 원근 크롭 서브메뉴
// ============================================================
import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/perspective_crop/perspective_transform_service.dart';

class PerspectiveSubMenu extends StatelessWidget {
  final EditPageController controller;
  const PerspectiveSubMenu({super.key, required this.controller});

  Future<void> _runTransform(BuildContext context) async {
    final index = controller.currentIndex;
    final points = controller.getCropPoints(index);
    final imageWidgetSize = controller.imageWidgetSize;
    if (points == null || imageWidgetSize == null) return;

    controller.setCropProcessing(true);
    try {
      final previewPath = await PerspectiveTransformService.transform(
        imagePath: controller.images[index],
        points: points,
        imageWidgetSize: imageWidgetSize,
      );
      controller.setCropPreview(previewPath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('변환 실패: $e')));
        print('Perspective transform error: $e');
      }
    } finally {
      controller.setCropProcessing(false);
    }
  }

  Future<void> _save(BuildContext context) async {
    final previewPath = controller.previewCropPath;
    if (previewPath == null) return;

    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('저장', style: TextStyle(color: Colors.white)),
        content: const Text(
          '새로 저장하게 됩니다.',
          style: TextStyle(color: Colors.white70),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () => Navigator.pop(ctx, false),
        //     child: const Text('새 파일로 저장'),
        //   ),
        //   TextButton(
        //     onPressed: () => Navigator.pop(ctx, true),
        //     child: const Text(
        //       '원본 덮어쓰기',
        //       style: TextStyle(color: Colors.redAccent),
        //     ),
        //   ),
        // ],
      ),
    );

    if (choice == null || !context.mounted) return;

    await PerspectiveTransformService.save(
      previewPath: previewPath,
      originalPath: controller.images[controller.currentIndex],
      // overwrite: choice,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장 완료')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPreview = controller.previewCropPath != null;
    final isProcessing = controller.isCropProcessing;

    return SubMenuShell(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: isProcessing ? null : () => _runTransform(context),
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
              label: Text(isProcessing ? '처리 중...' : '변환 적용'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: hasPreview ? () => _save(context) : null,
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
