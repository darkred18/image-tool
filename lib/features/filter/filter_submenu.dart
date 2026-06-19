import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/filter/filter_service.dart';

class FilterSubMenu extends ConsumerWidget {
  const FilterSubMenu({super.key});

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final images = ref.read(imagesProvider);
    final index = ref.read(currentIndexProvider);
    final state = ref.read(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    notifier.setFilterProcessing(true);
    try {
      final path = await FilterService.apply(
        imagePath: images[index],
        filterType: state.selectedFilter,
        strength: state.filterStrength,
      );
      notifier.setFilterPreview(path);
      ref.read(filterPreviewPathProvider.notifier).state = path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('필터 적용 실패: $e')));
      }
    } finally {
      notifier.setFilterProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    final filters = [
      (FilterType.edge, Icons.auto_fix_high, '엣지'),
      (FilterType.simplify, Icons.palette, '색상 단순화'),
      (FilterType.contrast, Icons.brightness_6, '명암 강조'),
      (FilterType.blur, Icons.blur_on, '부드럽게'),
    ];

    return SubMenuShell(
      children: [
        // ── 처리 중 인디케이터 ─────────────────────────────
        if (state.isFilterProcessing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '적용 중...',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        // ── 필터 선택 ──────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: filters.map((f) {
            final isSelected = state.selectedFilter == f.$1;
            return GestureDetector(
              onTap: () {
                final next = isSelected ? null : f.$1;
                notifier.setFilterType(next);
                if (next == null) {
                  ref.read(filterPreviewPathProvider.notifier).state = null;
                } else {
                  _apply(context, ref);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blueAccent.withValues(alpha: 0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.white24,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.$2,
                      color: isSelected ? Colors.blueAccent : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.$3,
                      style: TextStyle(
                        color: isSelected ? Colors.blueAccent : Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const Divider(color: Colors.white10, height: 24),

        // ── 강도 슬라이더 ──────────────────────────────────
        Row(
          children: [
            const SizedBox(
              width: 40,
              child: Text(
                '강도',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Expanded(
              child: Slider(
                value: state.filterStrength,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white12,
                onChanged: (v) => notifier.setFilterStrength(v),
                onChangeEnd: (v) => _apply(context, ref),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${(state.filterStrength * 100).toInt()}%',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
