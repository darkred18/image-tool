import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_tools/controller/providers.dart';
import 'package:image_tools/features/color_picker/color_picker_overlay.dart';
import 'package:image_tools/features/grid/grid_overlay.dart';
import 'package:image_tools/features/perspective_crop/perspective_crop_overlay.dart';
import 'package:image_tools/widgets/image_canvas.dart';
import 'package:image_tools/widgets/tool_submenu.dart';
import 'package:image_tools/widgets/top_bar.dart';
import 'package:image_tools/widgets/bottom_tool_bar.dart';

class GalleryEditScreen extends ConsumerStatefulWidget {
  const GalleryEditScreen({super.key});

  @override
  ConsumerState<GalleryEditScreen> createState() => _GalleryEditScreenState();
}

class _GalleryEditScreenState extends ConsumerState<GalleryEditScreen> {
  late final PageController _pageController;
  final Map<int, GlobalKey> _canvasKeys = {};

  GlobalKey _getKeyForIndex(int index) {
    return _canvasKeys.putIfAbsent(index, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    // Provider에 이미 index가 설정된 상태로 진입하므로 바로 읽어서 사용
    _pageController = PageController(
      initialPage: ref.read(currentIndexProvider),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(currentIndexProvider.notifier).state = index;
    resetEditStates(ref);
  }

  void _toggleBars() {
    final current = ref.read(barsVisibleProvider);
    ref.read(barsVisibleProvider.notifier).state = !current;
    if (current) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = ref.watch(imagesProvider);
    final activeTool = ref.watch(activeToolProvider);
    final isBarsVisible = ref.watch(barsVisibleProvider);
    final isZoomed = ref.watch(isZoomedProvider);
    final currentIndex = ref.watch(currentIndexProvider);
    final actualSize = ref.watch(currentImageWidgetSizeProvider);

    final isEditing = activeTool != EditTool.none;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isEditing) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💡 편집 중에는 슬라이드 뒤로가기가 제한됩니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
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
                controller: _pageController,
                itemCount: images.length,
                physics: isEditing
                    ? const NeverScrollableScrollPhysics()
                    : (isZoomed
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics()),
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final imageCanvas = ImageCanvas(
                    key: _getKeyForIndex(index),
                    imageUrl: images[index],
                    index: index,
                  );

                  // ── 일반 보기 모드 ──────────────────────────────
                  if (activeTool == EditTool.none) {
                    return GestureDetector(
                      onTap: _toggleBars,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: InteractiveViewer(
                          maxScale: 5.0,
                          minScale: 0.7,
                          onInteractionUpdate: (details) {
                            ref.read(isZoomedProvider.notifier).state =
                                details.scale > 1.0;
                          },
                          child: imageCanvas,
                        ),
                      ),
                    );
                  }

                  // ── 편집 모드 ───────────────────────────────────
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (index != currentIndex) {
                        return Center(child: imageCanvas);
                      }

                      if (actualSize == null || actualSize == Size.zero) {
                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(opacity: 0.0, child: imageCanvas),
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ],
                          ),
                        );
                      }

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
                                Positioned.fill(child: imageCanvas),

                                if (activeTool == EditTool.perspective)
                                  Positioned.fill(
                                    child: PerspectiveCropOverlay(
                                      imageSize: actualSize,
                                      index: index,
                                    ),
                                  ),

                                if (activeTool == EditTool.grid)
                                  Positioned.fill(
                                    child: GridOverlay(imageSize: actualSize),
                                  ),

                                if (activeTool == EditTool.colorPicker)
                                  Positioned.fill(
                                    child: ColorPickerOverlay(
                                      imageSize: actualSize,
                                      imageUrl: images[index],
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

            if (isBarsVisible)
              const Positioned(top: 0, left: 0, right: 0, child: TopBar()),

            if (isBarsVisible)
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: BottomToolBar(),
              ),

            if (isEditing)
              Positioned(
                left: 0,
                right: 0,
                bottom: 80 + MediaQuery.of(context).padding.bottom,
                child: const ToolSubMenu(),
              ),
          ],
        ),
      ),
    );
  }
}
