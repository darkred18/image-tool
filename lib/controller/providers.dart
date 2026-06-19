import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_tools/features/color_picker/color_alalysis_service.dart';
import 'package:image_tools/features/grid/grid_controller.dart';

// ============================================================
// 열거형
// ============================================================
enum EditTool { none, grid, colorPicker, perspective, filter }

enum FilterType { edge, simplify, contrast, blur }

// ============================================================
// [1] 갤러리 - 이미지 목록 / 현재 인덱스
// ============================================================

/// 편집할 이미지 경로 목록
final imagesProvider = StateProvider<List<String>>((ref) => []);

/// 현재 보고 있는 페이지 인덱스
final currentIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================
// [2] UI 상태
// ============================================================

/// 현재 활성화된 툴
final activeToolProvider = StateProvider<EditTool>((ref) => EditTool.none);

/// 상단/하단 바 표시 여부
final barsVisibleProvider = StateProvider<bool>((ref) => false);

/// 줌 상태
final isZoomedProvider = StateProvider<bool>((ref) => false);

// ============================================================
// [3] 이미지 렌더 크기 - 인덱스별 관리 (핵심 버그 수정)
// ============================================================

/// 각 페이지의 렌더링된 이미지 위젯 크기를 인덱스별로 보관
final imageWidgetSizesProvider = StateProvider<Map<int, Size>>((ref) => {});

/// 현재 인덱스의 이미지 위젯 크기만 꺼내는 편의 provider
final currentImageWidgetSizeProvider = Provider<Size?>((ref) {
  final index = ref.watch(currentIndexProvider);
  final sizes = ref.watch(imageWidgetSizesProvider);
  return sizes[index];
});

// ============================================================
// [4] 그리드  상태
// ============================================================
// providers.dart 상단 import 추가

// ============================================================
// [8] 그리드 상태
// ============================================================

class GridState {
  final GridType selectedGridType;
  final SquareBasis squareBasis;
  final int squareDivisions;
  final int horizontalDivisions;
  final int verticalDivisions;
  final Color gridColor;

  const GridState({
    this.selectedGridType = GridType.square,
    this.squareBasis = SquareBasis.width,
    this.squareDivisions = 3,
    this.horizontalDivisions = 3,
    this.verticalDivisions = 3,
    this.gridColor = Colors.white,
  });

  GridState copyWith({
    GridType? selectedGridType,
    SquareBasis? squareBasis,
    int? squareDivisions,
    int? horizontalDivisions,
    int? verticalDivisions,
    Color? gridColor,
  }) {
    return GridState(
      selectedGridType: selectedGridType ?? this.selectedGridType,
      squareBasis: squareBasis ?? this.squareBasis,
      squareDivisions: squareDivisions ?? this.squareDivisions,
      horizontalDivisions: horizontalDivisions ?? this.horizontalDivisions,
      verticalDivisions: verticalDivisions ?? this.verticalDivisions,
      gridColor: gridColor ?? this.gridColor,
    );
  }
}

class GridNotifier extends StateNotifier<GridState> {
  GridNotifier() : super(const GridState());

  void setGridType(GridType type) =>
      state = state.copyWith(selectedGridType: type);
  void setSquareBasis(SquareBasis basis) =>
      state = state.copyWith(squareBasis: basis);
  void updateSquareDivisions(int v) =>
      state = state.copyWith(squareDivisions: v);
  void updateHorizontalDivisions(int v) =>
      state = state.copyWith(horizontalDivisions: v);
  void updateVerticalDivisions(int v) =>
      state = state.copyWith(verticalDivisions: v);
  void updateGridColor(Color c) => state = state.copyWith(gridColor: c);
  void reset() => state = const GridState();
}

final gridProvider = StateNotifierProvider<GridNotifier, GridState>(
  (ref) => GridNotifier(),
);
// ============================================================
// [4] 원근 크롭 상태
// ============================================================

class PerspectiveCropState {
  final Map<int, List<Offset>> cropPoints; // 인덱스별 꼭짓점
  final Map<int, String?> previewPaths; // 인덱스별 미리보기 경로
  final bool isProcessing;

  const PerspectiveCropState({
    this.cropPoints = const {},
    this.previewPaths = const {},
    this.isProcessing = false,
  });

  PerspectiveCropState copyWith({
    Map<int, List<Offset>>? cropPoints,
    Map<int, String?>? previewPaths,
    bool? isProcessing,
  }) {
    return PerspectiveCropState(
      cropPoints: cropPoints ?? this.cropPoints,
      previewPaths: previewPaths ?? this.previewPaths,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class PerspectiveCropNotifier extends StateNotifier<PerspectiveCropState> {
  PerspectiveCropNotifier() : super(const PerspectiveCropState());

  void updatePoints(int index, List<Offset> points) {
    final newPoints = Map<int, List<Offset>>.from(state.cropPoints);
    final newPreviews = Map<int, String?>.from(state.previewPaths);
    newPoints[index] = points;
    newPreviews[index] = null; // 꼭짓점 바뀌면 미리보기 초기화
    state = state.copyWith(cropPoints: newPoints, previewPaths: newPreviews);
  }

  void setPreview(int index, String? path) {
    final newPreviews = Map<int, String?>.from(state.previewPaths);
    newPreviews[index] = path;
    state = state.copyWith(previewPaths: newPreviews);
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  void reset(int index) {
    final newPoints = Map<int, List<Offset>>.from(state.cropPoints);
    final newPreviews = Map<int, String?>.from(state.previewPaths);
    newPoints.remove(index);
    newPreviews.remove(index);
    state = state.copyWith(cropPoints: newPoints, previewPaths: newPreviews);
  }

  void resetAll() {
    state = const PerspectiveCropState();
  }
}

final perspectiveCropProvider =
    StateNotifierProvider<PerspectiveCropNotifier, PerspectiveCropState>(
      (ref) => PerspectiveCropNotifier(),
    );

// ============================================================
// [5] 컬러 피커 상태
// ============================================================

class ColorPickerState {
  final double boxSize;
  final ui.Image? previewImage;
  final List<PaintMix> paintMixes;
  final bool isAnalyzing;

  const ColorPickerState({
    this.boxSize = 50.0,
    this.previewImage,
    this.paintMixes = const [],
    this.isAnalyzing = false,
  });

  ColorPickerState copyWith({
    double? boxSize,
    ui.Image? previewImage,
    List<PaintMix>? paintMixes,
    bool? isAnalyzing,
  }) {
    return ColorPickerState(
      boxSize: boxSize ?? this.boxSize,
      previewImage: previewImage ?? this.previewImage,
      paintMixes: paintMixes ?? this.paintMixes,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    );
  }
}

class ColorPickerNotifier extends StateNotifier<ColorPickerState> {
  ColorPickerNotifier() : super(const ColorPickerState());

  void updateBoxSize(double size) => state = state.copyWith(boxSize: size);
  void updatePreviewImage(ui.Image? image) =>
      state = state.copyWith(previewImage: image);
  void setPaintMixes(List<PaintMix> mixes) =>
      state = state.copyWith(paintMixes: mixes);
  void setAnalyzing(bool value) => state = state.copyWith(isAnalyzing: value);
  void reset() => state = const ColorPickerState();
}

final colorPickerProvider =
    StateNotifierProvider<ColorPickerNotifier, ColorPickerState>(
      (ref) => ColorPickerNotifier(),
    );

// ============================================================
// [6] 필터 미리보기 경로
// ============================================================

// ============================================================
// [9] 필터 상태
// ============================================================

class FilterState {
  final FilterType? selectedFilter;
  final double filterStrength;
  final String? filterPreviewPath;
  final bool isFilterProcessing;

  const FilterState({
    this.selectedFilter = null,
    this.filterStrength = 0.5,
    this.filterPreviewPath,
    this.isFilterProcessing = false,
  });

  FilterState copyWith({
    FilterType? selectedFilter,
    double? filterStrength,
    String? filterPreviewPath,
    bool? clearPreview,
    bool? isFilterProcessing,
    bool? clearSelectedFilter,
  }) {
    return FilterState(
      selectedFilter: clearSelectedFilter == true
          ? null
          : (selectedFilter ?? this.selectedFilter),
      filterStrength: filterStrength ?? this.filterStrength,
      filterPreviewPath: clearPreview == true
          ? null
          : filterPreviewPath ?? this.filterPreviewPath,
      isFilterProcessing: isFilterProcessing ?? this.isFilterProcessing,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setFilterType(FilterType? type) => state = state.copyWith(
    selectedFilter: type,
    clearSelectedFilter: type == null,
    clearPreview: true,
  );
  void setFilterStrength(double value) =>
      state = state.copyWith(filterStrength: value);
  void setFilterPreview(String? path) =>
      state = state.copyWith(filterPreviewPath: path);
  void setFilterProcessing(bool value) =>
      state = state.copyWith(isFilterProcessing: value);
  void reset() => state = const FilterState();
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>(
  (ref) => FilterNotifier(),
);

// /// 필터 적용 후 미리보기 이미지 경로 (null이면 원본 표시)
final filterPreviewPathProvider = StateProvider<String?>((ref) => null);

// ============================================================
// [7] 페이지 이동 시 편집 상태 일괄 초기화 헬퍼
// ============================================================

/// 페이지 변경 시 호출 - 툴/바/줌/크롭 상태 초기화
void resetEditStates(WidgetRef ref) {
  ref.read(activeToolProvider.notifier).state = EditTool.none;
  ref.read(barsVisibleProvider.notifier).state = false;
  ref.read(isZoomedProvider.notifier).state = false;
  ref.read(perspectiveCropProvider.notifier).resetAll();
  ref.read(colorPickerProvider.notifier).reset();
  ref.read(filterPreviewPathProvider.notifier).state = null;
  ref.read(gridProvider.notifier).reset();
  ref.read(filterProvider.notifier).reset();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
