import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/grid/grid_controller.dart';
import 'package:image_tools/features/perspective_crop/perspective_transform_service.dart';

class ToolSubMenu extends StatelessWidget {
  final EditPageController controller;

  const ToolSubMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: switch (controller.activeTool) {
        EditTool.grid => _GridSubMenu(controller: controller),
        EditTool.colorPicker => _ColorPickerSubMenu(controller: controller),
        EditTool.perspective => _PerspectiveSubMenu(controller: controller),
        EditTool.none => const SizedBox.shrink(),
      },
    );
  }
}

// ============================================================
// 🔲 그리드 서브메뉴
// ============================================================
class _GridSubMenu extends StatelessWidget {
  final EditPageController controller;
  const _GridSubMenu({required this.controller});

  @override
  Widget build(BuildContext context) {
    final List<Color> palette = [
      Colors.white,
      Colors.yellow,
      Colors.redAccent,
      Colors.cyan,
      Colors.greenAccent,
    ];

    return _SubMenuShell(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _typeButton('정방형', GridType.square),
            _typeButton('가로만', GridType.horizontal),
            _typeButton('세로만', GridType.vertical),
          ],
        ),
        const Divider(color: Colors.white10, height: 24),
        if (controller.selectedGridType == GridType.square) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _basisButton('가로 기준', SquareBasis.width),
              const SizedBox(width: 12),
              _basisButton('세로 기준', SquareBasis.height),
            ],
          ),
          const SizedBox(height: 12),
          _sliderRow(
            label: '분할 수',
            value: controller.squareDivisions,
            onChanged: (v) => controller.updateSquareDivisions(v.toInt()),
          ),
        ] else if (controller.selectedGridType == GridType.horizontal) ...[
          _sliderRow(
            label: '가로 분할',
            value: controller.horizontalDivisions,
            onChanged: (v) => controller.updateHorizontalDivisions(v.toInt()),
          ),
        ] else ...[
          _sliderRow(
            label: '세로 분할',
            value: controller.verticalDivisions,
            onChanged: (v) => controller.updateVerticalDivisions(v.toInt()),
          ),
        ],
        const Divider(color: Colors.white10, height: 24),
        Row(
          children: [
            const Text(
              '선 색상',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: palette.map((color) {
                  final isSelected = controller.gridColor == color;
                  return GestureDetector(
                    onTap: () => controller.updateGridColor(color),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.white24,
                          width: isSelected ? 3.0 : 1.0,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: color == Colors.white
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _typeButton(String text, GridType type) {
    final isSelected = controller.selectedGridType == type;
    return ChoiceChip(
      label: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
      selected: isSelected,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.white10,
      onSelected: (_) => controller.setGridType(type),
    );
  }

  Widget _basisButton(String text, SquareBasis basis) {
    final isSelected = controller.squareBasis == basis;
    return ChoiceChip(
      label: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
      selected: isSelected,
      selectedColor: Colors.teal,
      backgroundColor: Colors.white10,
      onSelected: (_) => controller.setSquareBasis(basis),
    );
  }

  Widget _sliderRow({
    required String label,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label ($value)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 2,
            max: 12,
            divisions: 10,
            activeColor: Colors.blueAccent,
            inactiveColor: Colors.white12,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 🎨 색상 분석 서브메뉴
// ============================================================
class _ColorPickerSubMenu extends StatelessWidget {
  final EditPageController controller;
  const _ColorPickerSubMenu({required this.controller});

  @override
  Widget build(BuildContext context) {
    final paintMix = controller.paintMixes;

    return _SubMenuShell(
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

// ============================================================
// ✂️ 원근 크롭 서브메뉴
// ============================================================
class _PerspectiveSubMenu extends StatelessWidget {
  final EditPageController controller;
  const _PerspectiveSubMenu({required this.controller});

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
          '저장 방법을 선택하세요',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('새 파일로 저장'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '원본 덮어쓰기',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (choice == null || !context.mounted) return;

    await PerspectiveTransformService.save(
      previewPath: previewPath,
      originalPath: controller.images[controller.currentIndex],
      overwrite: choice,
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

    return _SubMenuShell(
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

// ============================================================
// 공용 서브메뉴 껍데기
// ============================================================
class _SubMenuShell extends StatelessWidget {
  final List<Widget> children;
  const _SubMenuShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(33, 33, 33, 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
