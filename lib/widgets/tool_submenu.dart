import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/color_picker/color_submenu.dart';
import 'package:image_tools/features/filter/filter_submenu.dart';
import 'package:image_tools/features/grid/grid_submenu.dart';
import 'package:image_tools/features/perspective_crop/perspective_submenu.dart';

class ToolSubMenu extends StatelessWidget {
  final EditPageController controller;

  const ToolSubMenu({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: switch (controller.activeTool) {
        EditTool.grid => GridSubMenu(controller: controller),
        EditTool.colorPicker => ColorPickerSubMenu(controller: controller),
        EditTool.perspective => PerspectiveSubMenu(controller: controller),
        EditTool.filter => FilterSubMenu(controller: controller),
        EditTool.none => const SizedBox.shrink(),
      },
    );
  }
}
