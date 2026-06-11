import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';

class TopBar extends StatelessWidget {
  final EditPageController controller;
  const TopBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                Text(
                  '${controller.currentIndex + 1} / ${controller.images.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
