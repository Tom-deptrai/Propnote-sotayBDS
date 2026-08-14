import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/area.dart';
import '../models/property.dart';
import '../models/property_status.dart';

/// Trạng thái trong phiên làm việc (in-memory) cho toàn bộ prototype.
///
/// Đây KHÔNG phải lớp lưu trữ thật (không SQLite/DB) — chỉ mô phỏng hành vi
/// CRUD trong bộ nhớ để các màn hình điều hướng và cập nhật lẫn nhau một
/// cách nhất quán trong lúc demo.
class AppState extends ChangeNotifier {
  final List<Property> _properties = List.of(mockProperties);
  final List<Property> _trash = [];
  final List<PropertyArea> _areas = List.of(mockAreas);
  final List<String> _propertyTypes = List.of(mockPropertyTypes);
  final List<String> _tagOptions = List.of(mockTagOptions);

  /// Hệ số phóng to/nhỏ marker trên bản đồ — lưu in-memory cho prototype.
  /// Đặt riêng dưới dạng field double đơn giản như thế này để sau này có
  /// thể thay bằng giá trị đọc/ghi từ local settings (VD: SharedPreferences)
  /// mà không cần đổi API của AppState.
  double _markerScale = markerScaleDefault;

  static const double markerScaleMin = 0.6;
  static const double markerScaleMax = 1.4;
  static const double markerScaleDefault = 1.0;

  List<Property> get properties => List.unmodifiable(_properties);
  List<Property> get trash => List.unmodifiable(_trash);
  List<PropertyArea> get areas => List.unmodifiable(_areas);
  List<String> get propertyTypes => List.unmodifiable(_propertyTypes);
  List<String> get tagOptions => List.unmodifiable(_tagOptions);
  double get markerScale => _markerScale;

  void setMarkerScale(double value) {
    _markerScale = value.clamp(markerScaleMin, markerScaleMax);
    notifyListeners();
  }

  void resetMarkerScale() => setMarkerScale(markerScaleDefault);

  PropertyArea? areaById(String id) {
    for (final a in _areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  String areaName(String id) => areaById(id)?.name ?? 'Chưa rõ khu vực';

  int propertyCountInArea(String areaId) =>
      _properties.where((p) => p.areaId == areaId).length;

  List<Property> propertiesInArea(String areaId) =>
      _properties.where((p) => p.areaId == areaId).toList();

  Property? propertyById(String id) {
    for (final p in _properties) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addProperty(Property property) {
    _properties.insert(0, property);
    notifyListeners();
  }

  void updateProperty(Property updated) {
    final index = _properties.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _properties[index] = updated;
      notifyListeners();
    }
  }

  void changeStatus(String propertyId, PropertyStatus status) {
    final p = propertyById(propertyId);
    if (p != null) updateProperty(p.copyWith(status: status));
  }

  void moveToArea(String propertyId, String areaId) {
    final p = propertyById(propertyId);
    if (p != null) updateProperty(p.copyWith(areaId: areaId));
  }

  void deleteProperty(String propertyId) {
    final index = _properties.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      final removed = _properties.removeAt(index);
      _trash.insert(0, removed);
      notifyListeners();
    }
  }

  void restoreFromTrash(String propertyId) {
    final index = _trash.indexWhere((p) => p.id == propertyId);
    if (index != -1) {
      final restored = _trash.removeAt(index);
      _properties.insert(0, restored);
      notifyListeners();
    }
  }

  void deletePermanently(String propertyId) {
    _trash.removeWhere((p) => p.id == propertyId);
    notifyListeners();
  }

  void emptyTrash() {
    _trash.clear();
    notifyListeners();
  }

  void addArea(String name) {
    final id = 'area_${DateTime.now().millisecondsSinceEpoch}';
    _areas.add(PropertyArea(id: id, name: name));
    notifyListeners();
  }

  void renameArea(String id, String newName) {
    final index = _areas.indexWhere((a) => a.id == id);
    if (index != -1) {
      _areas[index] = _areas[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  bool deleteArea(String id) {
    if (propertyCountInArea(id) > 0) return false;
    _areas.removeWhere((a) => a.id == id);
    notifyListeners();
    return true;
  }

  void reorderAreas(int oldIndex, int newIndex) {
    final area = _areas.removeAt(oldIndex);
    _areas.insert(newIndex, area);
    notifyListeners();
  }

  int propertyTypeUsageCount(String type) =>
      _properties.where((p) => p.propertyType == type).length;

  void addPropertyType(String name) {
    if (_propertyTypes.contains(name)) return;
    _propertyTypes.add(name);
    notifyListeners();
  }

  void renamePropertyType(String oldName, String newName) {
    final index = _propertyTypes.indexOf(oldName);
    if (index == -1 ||
        newName.isEmpty ||
        (newName != oldName && _propertyTypes.contains(newName))) {
      return;
    }
    _propertyTypes[index] = newName;
    for (var i = 0; i < _properties.length; i++) {
      if (_properties[i].propertyType == oldName) {
        _properties[i] = _properties[i].copyWith(propertyType: newName);
      }
    }
    notifyListeners();
  }

  bool deletePropertyType(String name) {
    if (propertyTypeUsageCount(name) > 0) return false;
    _propertyTypes.remove(name);
    notifyListeners();
    return true;
  }

  void reorderPropertyTypes(int oldIndex, int newIndex) {
    final type = _propertyTypes.removeAt(oldIndex);
    _propertyTypes.insert(newIndex, type);
    notifyListeners();
  }

  int tagUsageCount(String tag) =>
      _properties.where((p) => p.tags.contains(tag)).length;

  void addTagOption(String name) {
    if (_tagOptions.contains(name)) return;
    _tagOptions.add(name);
    notifyListeners();
  }

  void renameTagOption(String oldName, String newName) {
    final index = _tagOptions.indexOf(oldName);
    if (index == -1 ||
        newName.isEmpty ||
        (newName != oldName && _tagOptions.contains(newName))) {
      return;
    }
    _tagOptions[index] = newName;
    for (var i = 0; i < _properties.length; i++) {
      if (_properties[i].tags.contains(oldName)) {
        final updatedTags = _properties[i].tags
            .map((t) => t == oldName ? newName : t)
            .toList();
        _properties[i] = _properties[i].copyWith(tags: updatedTags);
      }
    }
    notifyListeners();
  }

  void deleteTagOption(String name) {
    _tagOptions.remove(name);
    for (var i = 0; i < _properties.length; i++) {
      if (_properties[i].tags.contains(name)) {
        final updatedTags = List.of(_properties[i].tags)..remove(name);
        _properties[i] = _properties[i].copyWith(tags: updatedTags);
      }
    }
    notifyListeners();
  }

  void reorderTagOptions(int oldIndex, int newIndex) {
    final tag = _tagOptions.removeAt(oldIndex);
    _tagOptions.insert(newIndex, tag);
    notifyListeners();
  }
}
