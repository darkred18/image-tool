import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_tools/features/perspective_crop/perspective_crop_controller.dart';
import 'package:image_tools/features/grid/grid_controller.dart';
import 'package:image_tools/features/color_picker/color_picker_controller.dart';

// ==========================================
// 🛠️ 현재 활성화된 편집 도구 열거형
// ==========================================
enum EditTool { none, grid, colorPicker, perspective }

/// 🎨 이미지 편집 및 갤러리 상태를 총괄하는 컨트롤러
class EditPageController extends ChangeNotifier
    with GridControllerMixin, ColorPickerMixin, PerspectiveCropMixin {
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
    // _isBarsVisible = !_isBarsVisible;

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
    resetGridSettings();
    resetColorPicker();
    resetAllCropPoints();
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
