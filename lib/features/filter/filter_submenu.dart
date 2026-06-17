import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/filter/filter_controller.dart';
import 'package:image_tools/features/filter/filter_service.dart';

class FilterSubMenu extends StatelessWidget {
  final EditPageController controller;
  const FilterSubMenu({super.key, required this.controller});

  Future<void> _apply(BuildContext context) async {
    controller.setFilterProcessing(true);
    try {
      final path = await FilterService.apply(
        imagePath: controller.images[controller.currentIndex],
        filterType: controller.selectedFilter,
        strength: controller.filterStrength,
      );
      controller.setFilterPreview(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('필터 적용 실패: $e')));
      }
    } finally {
      controller.setFilterProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = [
      (FilterType.edge, Icons.auto_fix_high, '엣지'),
      (FilterType.simplify, Icons.palette, '색상 단순화'),
      (FilterType.contrast, Icons.brightness_6, '명암 강조'),
      (FilterType.blur, Icons.blur_on, '부드럽게'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(33, 33, 33, 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 필터 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: filters.map((f) {
              final isSelected = controller.selectedFilter == f.$1;
              return GestureDetector(
                onTap: () {
                  controller.setFilterType(f.$1);
                  _apply(context);
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
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white54,
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
          // 강도 슬라이더
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
                  value: controller.filterStrength,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.blueAccent,
                  inactiveColor: Colors.white12,
                  onChanged: (v) => controller.setFilterStrength(v),
                  onChangeEnd: (v) => _apply(context), // 슬라이더 놓을 때 자동 적용
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '${(controller.filterStrength * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // // 적용 버튼
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton.icon(
          //     onPressed: controller.isFilterProcessing
          //         ? null
          //         : () => _apply(context),
          //     icon: controller.isFilterProcessing
          //         ? const SizedBox(
          //             width: 16,
          //             height: 16,
          //             child: CircularProgressIndicator(
          //               strokeWidth: 2,
          //               color: Colors.white,
          //             ),
          //           )
          //         : const Icon(Icons.check, size: 18),
          //     label: Text(controller.isFilterProcessing ? '처리 중...' : '필터 적용'),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.blueAccent,
          //       foregroundColor: Colors.white,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
