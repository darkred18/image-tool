import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/color_picker/color_submenu.dart';
import 'package:image_tools/features/filter/filter_submenu.dart';
import 'package:image_tools/features/grid/grid_submenu.dart';
import 'package:image_tools/features/perspective_crop/perspective_submenu.dart';

class ToolSubMenu extends ConsumerWidget {
  const ToolSubMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: switch (activeTool) {
        EditTool.grid => const GridSubMenu(),
        EditTool.colorPicker => const ColorPickerSubMenu(),
        EditTool.perspective => const PerspectiveSubMenu(),
        EditTool.filter => const FilterSubMenu(),
        EditTool.none => const SizedBox.shrink(),
      },
    );
  }
}
