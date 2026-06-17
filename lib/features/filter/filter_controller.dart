import 'package:flutter/material.dart';

enum FilterType { edge, simplify, contrast, blur }

mixin FilterControllerMixin on ChangeNotifier {
  FilterType _selectedFilter = FilterType.edge;
  FilterType get selectedFilter => _selectedFilter;

  double _filterStrength = 0.5;
  double get filterStrength => _filterStrength;

  String? _filterPreviewPath;
  String? get filterPreviewPath => _filterPreviewPath;

  bool _isFilterProcessing = false;
  bool get isFilterProcessing => _isFilterProcessing;

  void setFilterType(FilterType type) {
    if (_selectedFilter == type) return;
    _selectedFilter = type;
    _filterPreviewPath = null;
    notifyListeners();
  }

  void setFilterStrength(double value) {
    if (_filterStrength == value) return;
    _filterStrength = value;
    notifyListeners();
  }

  void setFilterPreview(String? path) {
    _filterPreviewPath = path;
    notifyListeners();
  }

  void setFilterProcessing(bool value) {
    _isFilterProcessing = value;
    notifyListeners();
  }

  void resetFilter() {
    _selectedFilter = FilterType.edge;
    _filterStrength = 0.5;
    _filterPreviewPath = null;
    _isFilterProcessing = false;
  }
}
