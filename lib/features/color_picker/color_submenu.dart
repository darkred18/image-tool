import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';

class ColorPickerSubMenu extends ConsumerWidget {
  const ColorPickerSubMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(colorPickerProvider);
    final notifier = ref.read(colorPickerProvider.notifier);

    return SubMenuShell(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 프리뷰 이미지 ────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(4),
              ),
              child: state.previewImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: RawImage(image: state.previewImage),
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
            // ── 물감 조합 결과 ────────────────────────────────
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
                  if (state.isAnalyzing)
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
                  else if (state.paintMixes.isEmpty)
                    const Text(
                      '박스를 드래그 후 놓으세요',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    )
                  else
                    ...state.paintMixes.expand(
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
        // ── 박스 크기 슬라이더 ────────────────────────────────
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '박스 크기 (${state.boxSize.toInt()})',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Expanded(
              child: Slider(
                value: state.boxSize,
                min: 10,
                max: 100,
                activeColor: Colors.blueAccent,
                inactiveColor: Colors.white12,
                onChanged: (v) => notifier.updateBoxSize(v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
