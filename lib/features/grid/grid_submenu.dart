import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/grid/grid_controller.dart';

class GridSubMenu extends StatelessWidget {
  final EditPageController controller;
  const GridSubMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final List<Color> palette = [
      Colors.white,
      Colors.yellow,
      Colors.redAccent,
      Colors.cyan,
      Colors.greenAccent,
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
          // ── 모드 선택 ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTypeButton('정방형', GridType.square),
              _buildTypeButton('가로만', GridType.horizontal),
              _buildTypeButton('세로만', GridType.vertical),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),

          // ── 모드별 슬라이더 ──────────────────────────────────────
          if (controller.selectedGridType == GridType.square) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBasisButton('가로 기준', SquareBasis.width),
                const SizedBox(width: 12),
                _buildBasisButton('세로 기준', SquareBasis.height),
              ],
            ),
            const SizedBox(height: 12),
            _buildSliderRow(
              label: '분할 수',
              value: controller.squareDivisions,
              onChanged: (val) => controller.updateSquareDivisions(val.toInt()),
            ),
          ] else if (controller.selectedGridType == GridType.horizontal) ...[
            _buildSliderRow(
              label: '가로 분할',
              value: controller.horizontalDivisions,
              onChanged: (val) =>
                  controller.updateHorizontalDivisions(val.toInt()),
            ),
          ] else ...[
            _buildSliderRow(
              label: '세로 분할',
              value: controller.verticalDivisions,
              onChanged: (val) =>
                  controller.updateVerticalDivisions(val.toInt()),
            ),
          ],

          const Divider(color: Colors.white10, height: 24),

          // ── 선 색상 ──────────────────────────────────────────────
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
      ),
    );
  }

  Widget _buildTypeButton(String text, GridType type) {
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

  Widget _buildBasisButton(String text, SquareBasis basis) {
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

  Widget _buildSliderRow({
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
