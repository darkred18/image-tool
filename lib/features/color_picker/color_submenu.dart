// ============================================================
// 🎨 색상 분석 서브메뉴
// ============================================================
import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';

class ColorPickerSubMenu extends StatelessWidget {
  final EditPageController controller;
  const ColorPickerSubMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final paintMix = controller.paintMixes;

    return SubMenuShell(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: 이미지 프리뷰 (ColorPickerOverlay에서 uiImage 전달 필요)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: controller.previewImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: RawImage(image: controller.previewImage),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.white24,
                        size: 28,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // 오른쪽: 물감 조합
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '물감 조합',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (controller.isAnalyzing)
                    const Row(
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
                          '분석 중...',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    )
                  else if (paintMix.isEmpty)
                    const Text(
                      '박스를 드래그 후 놓으세요',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    )
                  else
                    ...paintMix.expand(
                      (mix) => mix.components.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: Colors.white24),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.name,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                '${c.percent}%',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 20),
        // 박스 크기 슬라이더
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '박스 크기 (${controller.colorPickerBoxSize.toInt()})',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Expanded(
              child: Slider(
                value: controller.colorPickerBoxSize,
                min: 10,
                max: 100,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white12,
                onChanged: (v) => controller.updateColorPickerBoxSize(v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
