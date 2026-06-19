import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';

class BottomToolBar extends ConsumerWidget {
  const BottomToolBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        // ✅ 불투명 배경
        color: const Color(0xDD000000),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _ToolButton(
                  icon: Icons.crop,
                  label: '크롭',
                  tool: EditTool.perspective,
                ),
                _ToolButton(
                  icon: Icons.grid_on,
                  label: '그리드',
                  tool: EditTool.grid,
                ),
                _ToolButton(
                  icon: Icons.colorize,
                  label: '색상 분석',
                  tool: EditTool.colorPicker,
                ),
                _ToolButton(
                  icon: Icons.auto_awesome,
                  label: '필터',
                  tool: EditTool.filter,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final EditTool tool;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.tool,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final isActive = activeTool == tool;

    return GestureDetector(
      onTap: () {
        // ✅ 같은 툴 한 번 더 누르면 꺼짐
        ref.read(activeToolProvider.notifier).state = isActive
            ? EditTool.none
            : tool;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blueAccent.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.blueAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blueAccent : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blueAccent : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
