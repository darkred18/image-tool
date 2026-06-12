import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/widgets/draggable_image.dart';
import 'package:image_tools/widgets/image_canvas.dart';
import 'package:image_tools/widgets/tool_submenu.dart';
import 'package:image_tools/widgets/top_bar.dart';
import 'package:image_tools/widgets/bottom_tool_bar.dart';

class GalleryEditScreen extends StatefulWidget {
  final EditPageController controller;
  const GalleryEditScreen({super.key, required this.controller});

  @override
  State<GalleryEditScreen> createState() => _GalleryEditScreenState();
}

class _GalleryEditScreenState extends State<GalleryEditScreen> {
  late final EditPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bool isEditing = _controller.activeTool != EditTool.none;
        return PopScope(
          canPop: !isEditing,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('💡 편집 중에는 슬라이드 뒤로가기가 제한됩니다.')),
            );
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // ── 1. 메인 갤러리 ─────────────────────────────────────
                Positioned.fill(
                  child: PageView.builder(
                    controller: _controller.pageController,
                    itemCount: _controller.images.length,
                    physics: (isEditing || _controller.isZoomed)
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: _controller.updateIndex,
                    itemBuilder: (context, index) {
                      final imageCanvas = ImageCanvas(
                        imageUrl: _controller.images[index],
                        controller: _controller,
                      );

                      return GestureDetector(
                        onTap: _controller.toggleBars,
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 편집 모드: DraggableImage (자유 이동/줌)
                              // 일반 모드: InteractiveViewer (핀치줌)
                              if (isEditing)
                                DraggableImage(child: imageCanvas)
                              else
                                InteractiveViewer(
                                  clipBehavior: Clip.none,
                                  maxScale: 5.0,
                                  minScale: 1.0,
                                  onInteractionUpdate: (details) => _controller
                                      .setZoomed(details.scale > 1.0),
                                  child: imageCanvas,
                                ),
                              // if (_controller.activeTool == EditTool.colorPicker)
                              //   ColorPickerOverlay(
                              //     controller: _controller,
                              //     imageUrl: _controller.images[index],
                              //   ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── 2. 상단 바 ─────────────────────────────────────────
                if (_controller.isBarsVisible)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TopBar(controller: _controller),
                  ),

                // ── 3. 하단 툴바 ───────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomToolBar(controller: _controller),
                ),

                // ── 4. 툴 서브메뉴
                if (isEditing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: ToolSubMenu(controller: _controller),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
