import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/grid/grid_controller.dart';

class GridSubMenu extends ConsumerWidget {
  const GridSubMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grid = ref.watch(gridProvider);
    final notifier = ref.read(gridProvider.notifier);

    final List<Color> palette = [
      Colors.white,
      Colors.yellow,
      Colors.redAccent,
      Colors.cyan,
      Colors.greenAccent,
    ];

    return SubMenuShell(
      children: [
        // ── 모드 선택 ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTypeButton('정방형', GridType.square, grid, notifier),
            _buildTypeButton('가로만', GridType.horizontal, grid, notifier),
            _buildTypeButton('세로만', GridType.vertical, grid, notifier),
          ],
        ),
        const Divider(color: Colors.white10, height: 24),

        // ── 모드별 슬라이더 ────────────────────────────────────
        if (grid.selectedGridType == GridType.square) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBasisButton('가로 기준', SquareBasis.width, grid, notifier),
              const SizedBox(width: 12),
              _buildBasisButton('세로 기준', SquareBasis.height, grid, notifier),
            ],
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            label: '분할 수',
            value: grid.squareDivisions,
            onChanged: (val) => notifier.updateSquareDivisions(val.toInt()),
          ),
        ] else if (grid.selectedGridType == GridType.horizontal) ...[
          _buildSliderRow(
            label: '가로 분할',
            value: grid.horizontalDivisions,
            onChanged: (val) => notifier.updateHorizontalDivisions(val.toInt()),
          ),
        ] else ...[
          _buildSliderRow(
            label: '세로 분할',
            value: grid.verticalDivisions,
            onChanged: (val) => notifier.updateVerticalDivisions(val.toInt()),
          ),
        ],

        const Divider(color: Colors.white10, height: 24),

        // ── 선 색상 ────────────────────────────────────────────
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
                  final isSelected = grid.gridColor == color;
                  return GestureDetector(
                    onTap: () => notifier.updateGridColor(color),
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

  Widget _buildTypeButton(
    String text,
    GridType type,
    GridState grid,
    GridNotifier notifier,
  ) {
    final isSelected = grid.selectedGridType == type;
    return ChoiceChip(
      label: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
      selected: isSelected,
      selectedColor: Colors.blueAccent,
      backgroundColor: Colors.grey.shade700,
      onSelected: (_) => notifier.setGridType(type),
    );
  }

  Widget _buildBasisButton(
    String text,
    SquareBasis basis,
    GridState grid,
    GridNotifier notifier,
  ) {
    final isSelected = grid.squareBasis == basis;
    return ChoiceChip(
      label: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
      selected: isSelected,
      selectedColor: Colors.teal,
      backgroundColor: Colors.grey.shade700,
      onSelected: (_) => notifier.setSquareBasis(basis),
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
            min: 1,
            max: 11,
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
