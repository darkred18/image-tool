import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/perspective_crop/perspective_transform_service.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  Future<void> _saveToGallery(BuildContext context, WidgetRef ref) async {
    final index = ref.read(currentIndexProvider);
    final images = ref.read(imagesProvider);
    final filterPreviewPath = ref.read(filterPreviewPathProvider);
    final imagePath = filterPreviewPath ?? images[index];

    try {
      await PerspectiveTransformService.saveToSystemGallery(
        imagePath: imagePath,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ 갤러리에 저장되었습니다.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(imagesProvider);
    final currentIndex = ref.watch(currentIndexProvider);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        // ✅ 불투명 배경
        color: const Color(0xDD000000),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  '${currentIndex + 1} / ${images.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                // ✅ 저장 버튼
                IconButton(
                  icon: const Icon(Icons.save_alt, color: Colors.white),
                  tooltip: '갤러리에 저장',
                  onPressed: () => _saveToGallery(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
