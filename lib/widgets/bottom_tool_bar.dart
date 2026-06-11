import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';

class BottomToolBar extends StatelessWidget {
  final EditPageController controller;
  const BottomToolBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // 이벤트가 아래 이미지 GestureDetector로 전파되는 것을 차단
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.crop,
                  label: '크롭',
                  tool: EditTool.perspective,
                  controller: controller,
                ),
                _ToolButton(
                  icon: Icons.grid_on,
                  label: '그리드',
                  tool: EditTool.grid,
                  controller: controller,
                ),
                _ToolButton(
                  icon: Icons.colorize,
                  label: '색상 분석',
                  tool: EditTool.colorPicker,
                  controller: controller,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final EditTool tool;
  final EditPageController controller;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.tool,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = controller.activeTool == tool;

    return GestureDetector(
      onTap: () => controller.selectTool(tool),
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
