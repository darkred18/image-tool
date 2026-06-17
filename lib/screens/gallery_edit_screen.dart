import 'package:flutter/material.dart';
import 'package:image_tools/controller/edit_page_controller.dart';
import 'package:image_tools/features/color_picker/color_picker_overlay.dart';
import 'package:image_tools/features/grid/grid_overlay.dart';
import 'package:image_tools/features/perspective_crop/perspective_crop_overlay.dart';
import 'package:image_tools/widgets/image_canvas.dart';
import 'package:image_tools/widgets/tool_submenu.dart';
import 'package:image_tools/widgets/top_bar.dart';
import 'package:image_tools/widgets/bottom_tool_bar.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

class GalleryEditScreen extends StatefulWidget {
  final EditPageController controller;
  const GalleryEditScreen({super.key, required this.controller});

  @override
  State<GalleryEditScreen> createState() => _GalleryEditScreenState();
}

class _GalleryEditScreenState extends State<GalleryEditScreen> {
  late final EditPageController _controller;
  // 💡 인덱스별로 GlobalKey를 딱 하나씩만 유지하기 위한 보관함
  final Map<int, GlobalKey> _canvasKeys = {};
  // 인덱스에 맞는 키를 꺼내거나, 없으면 새로 만들어서 반환하는 헬퍼 함수
  GlobalKey _getKeyForIndex(int index) {
    return _canvasKeys.putIfAbsent(index, () => GlobalKey());
  }

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
          canPop: false, // 뒤로가기 자체는 허용하지 않음 (팝업이나 다이얼로그가 있으면 그쪽에서 처리)
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            if (isEditing) {
              // 🔒 1. 편집 중일 때는 뒤로가기를 완전히 무시하고 안내 스낵바만 출력합니다.
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💡 편집 중에는 슬라이드 뒤로가기가 제한됩니다.'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              // 🔓 2. 편집 중이 아닐 때는 정상적으로 뒤로
              Navigator.of(context).pop(result);
            }
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
                    physics: isEditing
                        ? const NeverScrollableScrollPhysics()
                        : (_controller.isZoomed
                              ? const NeverScrollableScrollPhysics()
                              : const BouncingScrollPhysics()),
                    onPageChanged: _controller.updateIndex,
                    itemBuilder: (context, index) {
                      final canvasKey = _getKeyForIndex(index);

                      final imageCanvas = ImageCanvas(
                        key: canvasKey,
                        imageUrl: _controller.images[index],
                        controller: _controller,
                      );

                      // ── 💡 [분기 1] 일반 보기 모드 ──────────────────────────────
                      if (_controller.activeTool == EditTool.none) {
                        return GestureDetector(
                          // 🎯 일반 모드에서는 이미지든 배경이든 탭하면 툴바가 켜고 꺼집니다.
                          onTap: () => _controller.toggleBars(),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: InteractiveViewer(
                              maxScale: 5.0,
                              minScale: 0.7,
                              onInteractionUpdate: (details) =>
                                  _controller.setZoomed(details.scale > 1.0),
                              child: imageCanvas,
                            ),
                          ),
                        );
                      }
                      // ── 💡 2. 원근 크롭 편집 모드: 마진을 무한대로 주어 자유롭게 이동 ────────
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final actualSize = _controller.imageWidgetSize;
                          // 아직 이미지 실제 사이즈가 계산되기 전이라면 로딩 대기 처리
                          if (actualSize == null || actualSize == Size.zero) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // 🎯 [핵심 교정] 이미지 크기의 정확히 절반만 마진으로 설정합니다.
                          // 이렇게 하면 이미지가 사방 경계선 밖으로 자신의 '절반' 크기만큼만 밀려나고 턱 걸립니다.
                          final marginX = actualSize.width * 0.5;
                          final marginY = actualSize.height * 0.5;

                          return InteractiveViewer(
                            boundaryMargin: EdgeInsets.symmetric(
                              horizontal: marginX,
                              vertical: marginY,
                            ),
                            maxScale: 5.0,
                            minScale: 0.7,
                            child: Center(
                              child: SizedBox(
                                width: actualSize.width,
                                height: actualSize.height,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // [밑바탕] 이미지 본체
                                    Positioned.fill(child: imageCanvas),
                                    // 1. 원근 크롭 탭일 때
                                    if (_controller.activeTool ==
                                        EditTool.perspective)
                                      Positioned.fill(
                                        child: PerspectiveCropOverlay(
                                          controller: _controller,
                                          imageSize: actualSize,
                                        ),
                                      ),

                                    // 2. 그리드(격자) 탭일 때
                                    if (_controller.activeTool == EditTool.grid)
                                      Positioned.fill(
                                        child: GridOverlay(
                                          controller: _controller,
                                          imageSize: actualSize,
                                        ),
                                      ),

                                    // 3. 컬러 피커(색상 추출) 탭일 때
                                    if (_controller.activeTool ==
                                        EditTool.colorPicker)
                                      Positioned.fill(
                                        child: ColorPickerOverlay(
                                          controller: _controller,
                                          imageSize: actualSize,
                                          imageUrl: _controller.images[index],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                if (_controller.isBarsVisible)
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
