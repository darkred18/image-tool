import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_tools/features/filter/filter_controller.dart';
import 'package:image_tools/features/perspective_crop/perspective_crop_controller.dart';
import 'package:image_tools/features/grid/grid_controller.dart';
import 'package:image_tools/features/color_picker/color_picker_controller.dart';

// ==========================================
// 🛠️ 현재 활성화된 편집 도구 열거형
// ==========================================
enum EditTool { none, grid, colorPicker, perspective, filter }

/// 🎨 이미지 편집 및 갤러리 상태를 총괄하는 컨트롤러
class EditPageController extends ChangeNotifier
    with
        GridControllerMixin,
        ColorPickerMixin,
        PerspectiveCropMixin,
        FilterControllerMixin {
  // ==========================================
  // 📱 [1] 기본 네비게이션 및 갤러리 상태
  // ==========================================
  final List<String> images;
  int currentIndex;
  late final PageController pageController;

  // ==========================================
  // 🛠️ [2] 현재 활성 편집 도구 상태
  // ==========================================
  EditTool _activeTool = EditTool.none;
  EditTool get activeTool => _activeTool;

  // ==========================================
  // 🔍 [3] 줌 상태
  // ==========================================
  bool _isZoomed = false;
  bool get isZoomed => _isZoomed;

  // ==========================================
  // 👁️ [4] 상단/하단 UI 바 표시 여부
  // ==========================================
  bool _isBarsVisible = false;
  bool get isBarsVisible => _isBarsVisible;

  // ==========================================
  // 📐 [5] 크롭 상태
  // ==========================================
  String currentCropRatio = 'Free';
  bool isCropMode = false;

  // ------------------------------------------
  // ✨ 생성자
  // ------------------------------------------
  EditPageController({required this.images, required int initialIndex})
    : currentIndex = initialIndex {
    pageController = PageController(initialPage: initialIndex);
  }

  Offset _dragOffset = Offset.zero;
  double _dragScale = 1.0;
  double _previousDragScale = 1.0;
  Offset get dragOffset => _dragOffset;
  double get dragScale => _dragScale;

  void onDragScaleStart() {
    _previousDragScale = _dragScale;
  }

  void onDragScaleUpdate(Offset focalPointDelta, double scale) {
    _dragOffset += focalPointDelta;
    _dragScale = (_previousDragScale * scale).clamp(0.5, 5.0);
    notifyListeners();
  }
  // ==========================================
  // 🔄 상태 변경 메서드
  // ==========================================

  void updateIndex(int index) {
    if (currentIndex == index) return;
    currentIndex = index;
    _resetEditStates();
    notifyListeners();
  }

  void selectTool(EditTool tool) {
    // 도구를 선택할 때는 bars가 보이는 상태여야 함
    _activeTool = (_activeTool == tool) ? EditTool.none : tool;
    notifyListeners();
  }

  void setZoomed(bool zoomed) {
    if (_isZoomed == zoomed) return;
    _isZoomed = zoomed;
    notifyListeners();
  }

  /// 이미지 탭 시 상단/하단 UI 바만 토글
  /// - 도구 활성 상태와 무관하게 bars 표시/숨김만 전환
  /// - 그리드/색상분석 등 활성 도구 상태는 유지됨
  void toggleBars() {
    _isBarsVisible = !_isBarsVisible;

    // 시스템 UI 모드도 함께 전환
    if (!_isBarsVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    notifyListeners();
  }

  void setCropRatio(String ratio) {
    currentCropRatio = ratio;
    notifyListeners();
  }

  void toggleCropMode(bool active) {
    isCropMode = active;
    notifyListeners();
  }

  void _resetEditStates() {
    _activeTool = EditTool.none;
    _isZoomed = false;
    _isBarsVisible = false;
    currentCropRatio = 'Free';
    isCropMode = false;
    _dragOffset = Offset.zero;
    _dragScale = 1.0;
    _previousDragScale = 1.0;
    // resetGridSettings();
    resetColorPicker();
    resetAllCropPoints();
    resetFilter();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 화면 나갈 때 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    pageController.dispose();
    super.dispose();
  }
}

// ============================================================
// 공용 서브메뉴 껍데기
// ============================================================
class SubMenuShell extends StatelessWidget {
  final List<Widget> children;
  const SubMenuShell({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(33, 33, 33, 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
