import 'package:flutter/material.dart';

/// 그리드 모드
/// - square   : 정사각형 셀 (가로기준 or 세로기준 서브옵션)
/// - horizontal: 가로 분할선만 (수평선)
/// - vertical  : 세로 분할선만 (수직선)
enum GridType { square, horizontal, vertical }

/// 정방형 모드에서 기준 축
enum SquareBasis { width, height }

mixin GridControllerMixin on ChangeNotifier {
  // ── 모드 ──────────────────────────────────
  GridType _selectedGridType = GridType.square;
  GridType get selectedGridType => _selectedGridType;

  // ── 정방형 기준 축 ─────────────────────────
  SquareBasis _squareBasis = SquareBasis.width;
  SquareBasis get squareBasis => _squareBasis;

  // ── 분할 수 ───────────────────────────────
  // square / horizontal / vertical 모두 단일 슬라이더 사용
  // square   → squareDivisions
  // horizontal → horizontalDivisions (가로 분할선 개수)
  // vertical   → verticalDivisions   (세로 분할선 개수)
  int _squareDivisions = 3;
  int _horizontalDivisions = 3;
  int _verticalDivisions = 3;

  int get squareDivisions => _squareDivisions;
  int get horizontalDivisions => _horizontalDivisions;
  int get verticalDivisions => _verticalDivisions;

  // ── 선 색상 ───────────────────────────────
  Color _gridColor = Colors.white;
  Color get gridColor => _gridColor;

  bool _isGridVisible = false;
  bool get isGridVisible => _isGridVisible;

  // ── 메서드 ───────────────────────────────
  void setGridType(GridType type) {
    if (_selectedGridType == type) return;
    _selectedGridType = type;
    notifyListeners();
  }

  void setSquareBasis(SquareBasis basis) {
    if (_squareBasis == basis) return;
    _squareBasis = basis;
    notifyListeners();
  }

  void updateSquareDivisions(int value) {
    if (_squareDivisions == value) return;
    _squareDivisions = value;
    notifyListeners();
  }

  void updateHorizontalDivisions(int value) {
    if (_horizontalDivisions == value) return;
    _horizontalDivisions = value;
    notifyListeners();
  }

  void updateVerticalDivisions(int value) {
    if (_verticalDivisions == value) return;
    _verticalDivisions = value;
    notifyListeners();
  }

  void updateGridColor(Color color) {
    if (_gridColor == color) return;
    _gridColor = color;
    notifyListeners();
  }

  void resetGridSettings() {
    _selectedGridType = GridType.square;
    _squareBasis = SquareBasis.width;
    _squareDivisions = 3;
    _horizontalDivisions = 3;
    _verticalDivisions = 3;
    _gridColor = Colors.white;
  }
}
