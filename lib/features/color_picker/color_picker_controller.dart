import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_tools/features/color_picker/color_alalysis_service.dart';

mixin ColorPickerMixin on ChangeNotifier {
  // 박스 크기
  double _colorPickerBoxSize = 50.0;
  double get colorPickerBoxSize => _colorPickerBoxSize;

  // 프리뷰 이미지
  ui.Image? _previewImage;
  ui.Image? get previewImage => _previewImage;

  // 분석 결과
  List<PaintMix> _paintMixes = [];
  List<PaintMix> get paintMixes => _paintMixes;

  // 분석 중 여부
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  void updateColorPickerBoxSize(double size) {
    if (_colorPickerBoxSize == size) return;
    _colorPickerBoxSize = size;
    notifyListeners();
  }

  void updatePreviewImage(ui.Image? image) {
    _previewImage = image;
    notifyListeners();
  }

  void setPaintMixes(List<PaintMix> mixes) {
    _paintMixes = mixes;
    notifyListeners();
  }

  void setAnalyzing(bool value) {
    _isAnalyzing = value;
    notifyListeners();
  }

  void resetColorPicker() {
    _colorPickerBoxSize = 50.0;
    _previewImage = null;
    _paintMixes = [];
    _isAnalyzing = false;
  }
}
