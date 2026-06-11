import 'package:flutter/material.dart';

mixin PerspectiveCropMixin on ChangeNotifier {
  // 이미지 인덱스별 꼭짓점 저장
  // 한 번 설정된 꼭짓점은 같은 이미지에서 유지됨
  final Map<int, List<Offset>> _cropPoints = {};

  // 현재 변환된 이미지 경로 (미리보기용)
  String? _previewCropPath;
  String? get previewCropPath => _previewCropPath;

  // 처리 중 여부
  bool _isCropProcessing = false;
  bool get isCropProcessing => _isCropProcessing;

  /// 현재 인덱스의 꼭짓점 반환
  /// 없으면 null (PerspectiveCropOverlay에서 imageSize 기준으로 초기화)
  List<Offset>? getCropPoints(int index) => _cropPoints[index];

  /// 꼭짓점 업데이트 (드래그 시 호출)
  void updateCropPoints(int index, List<Offset> points) {
    _cropPoints[index] = points;
    // 꼭짓점이 바뀌면 기존 미리보기 초기화
    _previewCropPath = null;
    notifyListeners();
  }

  /// 미리보기 경로 업데이트 (변환 완료 후 호출)
  void setCropPreview(String? path) {
    _previewCropPath = path;
    notifyListeners();
  }

  void setCropProcessing(bool value) {
    _isCropProcessing = value;
    notifyListeners();
  }

  void resetPerspectiveCrop(int index) {
    _cropPoints.remove(index);
    _previewCropPath = null;
    _isCropProcessing = false;
  }

  // 렌더링된 이미지 크기 (ImageCanvas에서 업데이트)
  Size? _imageWidgetSize;
  Size? get imageWidgetSize => _imageWidgetSize;

  void updateImageWidgetSize(Size size) {
    if (_imageWidgetSize == size) return;
    _imageWidgetSize = size;
  }

  void resetAllCropPoints() {
    _cropPoints.clear();
    _previewCropPath = null;
    _isCropProcessing = false;
  }
}
