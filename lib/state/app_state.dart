import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import '../data/repositories/app_repository.dart';
import '../data/services/media_storage.dart';
import '../models/area.dart';
import '../models/geo_point.dart';
import '../models/property.dart';
import '../models/property_status.dart';
import '../models/property_tag.dart';
import '../models/property_type.dart';

/// State façade giữa UI và repository.
///
/// Production truyền [repository] và gọi [initialize]. Constructor không có
/// repository chỉ dành cho widget/unit tests hiện tại, dùng fixture in-memory
/// để các test UI không phụ thuộc platform SQLite.
class AppState extends ChangeNotifier {
  final AppRepository? _repository;
  final MediaStorage? mediaStorage;
  final Uuid _uuid;

  late List<Property> _properties;
  late List<Property> _trash;
  late List<PropertyArea> _areas;
  late List<PropertyType> _propertyTypeModels;
  late List<PropertyTag> _tagModels;

  double _markerScale = markerScaleDefault;
  GeoPoint? _lastMapLocation;
  Future<void> _settingWrite = Future.value();
  bool _isLoading = false;
  bool _isInitialized = false;
  Object? _lastError;

  static const double markerScaleMin = 0.6;
  static const double markerScaleMax = 1.4;
  static const double markerScaleDefault = 1.0;
  static const String _lastMapLocationKey = 'last_map_location';

  AppState({AppRepository? repository, this.mediaStorage, Uuid? uuid})
    : _repository = repository,
      _uuid = uuid ?? const Uuid() {
    if (repository == null) {
      _areas = [
        for (var i = 0; i < mockAreas.length; i++)
          mockAreas[i].copyWith(sortOrder: i),
      ];
      _propertyTypeModels = [
        for (var i = 0; i < mockPropertyTypes.length; i++)
          PropertyType(
            id: 'fixture_type_$i',
            name: mockPropertyTypes[i],
            sortOrder: i,
          ),
      ];
      _tagModels = [
        for (var i = 0; i < mockTagOptions.length; i++)
          PropertyTag(
            id: 'fixture_tag_$i',
            name: mockTagOptions[i],
            sortOrder: i,
          ),
      ];
      _properties = mockProperties
          .map(_hydrateFixtureProperty)
          .toList(growable: true);
      _trash = [];
      _isInitialized = true;
    } else {
      _properties = [];
      _trash = [];
      _areas = [];
      _propertyTypeModels = [];
      _tagModels = [];
    }
  }

  List<Property> get properties => List.unmodifiable(_properties);
  List<Property> get trash => List.unmodifiable(_trash);
  List<PropertyArea> get areas => List.unmodifiable(_areas);
  List<PropertyType> get propertyTypeModels =>
      List.unmodifiable(_propertyTypeModels);
  List<PropertyTag> get tagModels => List.unmodifiable(_tagModels);
  List<String> get propertyTypes =>
      _propertyTypeModels.map((type) => type.name).toList(growable: false);
  List<String> get tagOptions =>
      _tagModels.map((tag) => tag.name).toList(growable: false);
  double get markerScale => _markerScale;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  Object? get lastError => _lastError;

  String createId() => _uuid.v4();

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final snapshot = await _repository!.loadSnapshot();
      _properties = snapshot.properties.toList();
      _trash = snapshot.trash.toList();
      _areas = snapshot.areas.toList();
      _propertyTypeModels = snapshot.propertyTypes.toList();
      _tagModels = snapshot.tags.toList();
      _markerScale = snapshot.markerScale.clamp(markerScaleMin, markerScaleMax);
      _lastMapLocation = _decodeGeoPoint(
        await _repository.readSetting(_lastMapLocationKey),
      );
      _isInitialized = true;
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_repository == null) return;
    _isInitialized = false;
    try {
      await initialize();
    } catch (_) {
      _properties = [];
      _trash = [];
      _areas = [];
      _propertyTypeModels = [];
      _tagModels = [];
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Future<void> setMarkerScale(double value) {
    if (_repository != null && !_isInitialized) {
      return Future.error(StateError('Dữ liệu ứng dụng chưa sẵn sàng'));
    }
    final previous = _markerScale;
    final next = value.clamp(markerScaleMin, markerScaleMax);
    if (next == previous) return Future.value();
    _markerScale = next;
    notifyListeners();

    final repository = _repository;
    if (repository == null) return Future.value();
    final write = _settingWrite.then(
      (_) => repository.writeSetting('marker_scale', next.toString()),
    );
    _settingWrite = write.catchError((_) {});
    return write.catchError((Object error) {
      _lastError = error;
      if (_markerScale == next) _markerScale = previous;
      notifyListeners();
    });
  }

  Future<void> resetMarkerScale() => setMarkerScale(markerScaleDefault);

  /// Vị trí bản đồ gần nhất người dùng thực sự dùng (GPS thành công hoặc
  /// xác nhận trên location picker) — dùng làm initial camera thay vì quay
  /// về một toạ độ mặc định vô lý khi người dùng đã có lịch sử dùng app.
  GeoPoint? get lastMapLocation => _lastMapLocation;

  Future<void> setLastMapLocation(GeoPoint point) {
    if (_lastMapLocation == point) return Future.value();
    _lastMapLocation = point;
    notifyListeners();

    final repository = _repository;
    if (repository == null) return Future.value();
    final write = _settingWrite.then(
      (_) =>
          repository.writeSetting(_lastMapLocationKey, _encodeGeoPoint(point)),
    );
    _settingWrite = write.catchError((_) {});
    return write.catchError((_) {
      // Vị trí map gần nhất chỉ là tiện ích UX — lỗi ghi không cần rethrow
      // lên UI, giữ nguyên giá trị đã cập nhật trong bộ nhớ.
    });
  }

  static String _encodeGeoPoint(GeoPoint point) =>
      '${point.latitude},${point.longitude}';

  static GeoPoint? _decodeGeoPoint(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    final point = GeoPoint(latitude: lat, longitude: lng);
    return point.isValid ? point : null;
  }

  PropertyArea? areaById(String id) {
    for (final area in _areas) {
      if (area.id == id) return area;
    }
    return null;
  }

  String areaName(String id) => areaById(id)?.name ?? 'Chưa rõ khu vực';

  int propertyCountInArea(String areaId) =>
      _allProperties.where((property) => property.areaId == areaId).length;

  List<Property> propertiesInArea(String areaId) =>
      _properties.where((property) => property.areaId == areaId).toList();

  Property? propertyById(String id) {
    for (final property in _properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  Future<void> addProperty(Property property) async {
    final normalized = _normalizeProperty(
      property.copyWith(updatedAt: DateTime.now()),
    );
    await _persist(() => _repository?.saveProperty(normalized));
    _properties.insert(0, normalized);
    notifyListeners();
  }

  Future<void> updateProperty(Property updated) async {
    final index = _properties.indexWhere(
      (property) => property.id == updated.id,
    );
    if (index == -1) {
      throw StateError('Không tìm thấy BĐS: ${updated.id}');
    }
    final normalized = _normalizeProperty(
      updated.copyWith(updatedAt: DateTime.now()),
    );
    await _persist(() => _repository?.saveProperty(normalized));
    _properties[index] = normalized;
    notifyListeners();
  }

  Future<void> changeStatus(String propertyId, PropertyStatus status) async {
    final property = propertyById(propertyId);
    if (property == null) throw StateError('Không tìm thấy BĐS: $propertyId');
    await updateProperty(property.copyWith(status: status));
  }

  Future<void> moveToArea(String propertyId, String areaId) async {
    final property = propertyById(propertyId);
    if (property == null) throw StateError('Không tìm thấy BĐS: $propertyId');
    if (areaById(areaId) == null) {
      throw StateError('Không tìm thấy khu vực: $areaId');
    }
    await updateProperty(property.copyWith(areaId: areaId));
  }

  Future<void> deleteProperty(String propertyId) async {
    final index = _properties.indexWhere(
      (property) => property.id == propertyId,
    );
    if (index == -1) throw StateError('Không tìm thấy BĐS: $propertyId');
    final deletedAt = DateTime.now();
    await _persist(
      () => _repository?.movePropertyToTrash(propertyId, deletedAt),
    );
    final removed = _properties
        .removeAt(index)
        .copyWith(deletedAt: deletedAt, updatedAt: deletedAt);
    _trash.insert(0, removed);
    notifyListeners();
  }

  Future<void> restoreFromTrash(String propertyId) async {
    final index = _trash.indexWhere((property) => property.id == propertyId);
    if (index == -1) {
      throw StateError('Không tìm thấy BĐS trong thùng rác: $propertyId');
    }
    final updatedAt = DateTime.now();
    await _persist(() => _repository?.restoreProperty(propertyId, updatedAt));
    final restored = _trash
        .removeAt(index)
        .copyWith(deletedAt: null, updatedAt: updatedAt);
    _properties.insert(0, restored);
    notifyListeners();
  }

  Future<List<String>> deletePermanently(String propertyId) async {
    final index = _trash.indexWhere((property) => property.id == propertyId);
    if (index == -1) {
      throw StateError('Không tìm thấy BĐS trong thùng rác: $propertyId');
    }
    final staged = await mediaStorage?.stagePropertyDeletion(propertyId);
    PropertyAssetPaths? assets;
    try {
      assets = await _persist(
        () => _repository?.deletePropertyPermanently(propertyId),
      );
    } catch (_) {
      await staged?.rollback();
      rethrow;
    }
    _trash.removeWhere((property) => property.id == propertyId);
    notifyListeners();
    final paths = assets?.relativePaths ?? const <String>[];
    try {
      await mediaStorage?.deletePaths(paths);
      await staged?.complete();
    } catch (error, stackTrace) {
      debugPrint('Không thể dọn media đã xoá: $error\n$stackTrace');
      try {
        await _reconcileMedia();
      } catch (_) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
    return paths;
  }

  Future<List<PropertyAssetPaths>> emptyTrash() async {
    final staged = <StagedPropertyDeletion>[];
    List<PropertyAssetPaths>? assets;
    try {
      if (mediaStorage != null) {
        for (final property in _trash) {
          staged.add(await mediaStorage!.stagePropertyDeletion(property.id));
        }
      }
      assets = await _persist(() => _repository?.emptyTrash());
    } catch (_) {
      for (final deletion in staged.reversed) {
        await deletion.rollback();
      }
      rethrow;
    }
    _trash.clear();
    notifyListeners();
    try {
      for (final asset in assets ?? const <PropertyAssetPaths>[]) {
        await mediaStorage?.deletePaths(asset.relativePaths);
      }
      for (final deletion in staged) {
        await deletion.complete();
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Không thể dọn toàn bộ media trong thùng rác: $error\n$stackTrace',
      );
      try {
        await _reconcileMedia();
      } catch (_) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
    return assets ?? const [];
  }

  Future<void> addArea(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || _containsName(_areas, normalized)) return;
    final area = PropertyArea(
      id: _uuid.v4(),
      name: normalized,
      sortOrder: _areas.length,
    );
    await _persist(() => _repository?.saveArea(area));
    _areas.add(area);
    notifyListeners();
  }

  Future<bool> renameArea(String id, String newName) async {
    final index = _areas.indexWhere((area) => area.id == id);
    final normalized = newName.trim();
    if (index == -1 ||
        normalized.isEmpty ||
        _areas.any(
          (area) =>
              area.id != id &&
              area.name.toLowerCase() == normalized.toLowerCase(),
        )) {
      return false;
    }
    final updated = _areas[index].copyWith(name: normalized);
    await _persist(() => _repository?.saveArea(updated));
    _areas[index] = updated;
    notifyListeners();
    return true;
  }

  Future<bool> deleteArea(String id) async {
    if (propertyCountInArea(id) > 0) return false;
    final index = _areas.indexWhere((area) => area.id == id);
    if (index == -1) return false;
    await _persist(() => _repository?.deleteArea(id));
    _areas.removeAt(index);
    notifyListeners();
    return true;
  }

  Future<void> reorderAreas(int oldIndex, int newIndex) async {
    final updated = List<PropertyArea>.of(_areas);
    final area = updated.removeAt(oldIndex);
    updated.insert(newIndex, area);
    final normalized = [
      for (var i = 0; i < updated.length; i++)
        updated[i].copyWith(sortOrder: i),
    ];
    await _persist(
      () =>
          _repository?.reorderAreas(normalized.map((item) => item.id).toList()),
    );
    _areas = normalized;
    notifyListeners();
  }

  int propertyTypeUsageCount(String type) =>
      _allProperties.where((property) => property.propertyType == type).length;

  Future<void> addPropertyType(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || _typeByName(normalized) != null) return;
    final type = PropertyType(
      id: _uuid.v4(),
      name: normalized,
      sortOrder: _propertyTypeModels.length,
    );
    await _persist(() => _repository?.savePropertyType(type));
    _propertyTypeModels.add(type);
    notifyListeners();
  }

  Future<bool> renamePropertyType(String oldName, String newName) async {
    final index = _propertyTypeModels.indexWhere(
      (type) => type.name == oldName,
    );
    final normalized = newName.trim();
    if (index == -1 ||
        normalized.isEmpty ||
        _propertyTypeModels.any(
          (type) =>
              type.id != _propertyTypeModels[index].id &&
              type.name.toLowerCase() == normalized.toLowerCase(),
        )) {
      return false;
    }
    final current = _propertyTypeModels[index];
    final updated = current.copyWith(name: normalized);
    await _persist(() => _repository?.savePropertyType(updated));
    _propertyTypeModels[index] = updated;
    _replaceProperties(
      (property) => property.propertyTypeId == current.id
          ? property.copyWith(propertyType: normalized)
          : property,
    );
    notifyListeners();
    return true;
  }

  Future<bool> deletePropertyType(String name) async {
    if (propertyTypeUsageCount(name) > 0) return false;
    final index = _propertyTypeModels.indexWhere((type) => type.name == name);
    if (index == -1) return false;
    final type = _propertyTypeModels[index];
    await _persist(() => _repository?.deletePropertyType(type.id));
    _propertyTypeModels.removeAt(index);
    notifyListeners();
    return true;
  }

  Future<void> reorderPropertyTypes(int oldIndex, int newIndex) async {
    final updated = List<PropertyType>.of(_propertyTypeModels);
    final type = updated.removeAt(oldIndex);
    updated.insert(newIndex, type);
    final normalized = [
      for (var i = 0; i < updated.length; i++)
        updated[i].copyWith(sortOrder: i),
    ];
    await _persist(
      () => _repository?.reorderPropertyTypes(
        normalized.map((item) => item.id).toList(),
      ),
    );
    _propertyTypeModels = normalized;
    notifyListeners();
  }

  int tagUsageCount(String tag) =>
      _allProperties.where((property) => property.tags.contains(tag)).length;

  Future<void> addTagOption(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty || _tagByName(normalized) != null) return;
    final tag = PropertyTag(
      id: _uuid.v4(),
      name: normalized,
      sortOrder: _tagModels.length,
    );
    await _persist(() => _repository?.saveTag(tag));
    _tagModels.add(tag);
    notifyListeners();
  }

  Future<bool> renameTagOption(String oldName, String newName) async {
    final index = _tagModels.indexWhere((tag) => tag.name == oldName);
    final normalized = newName.trim();
    if (index == -1 ||
        normalized.isEmpty ||
        _tagModels.any(
          (tag) =>
              tag.id != _tagModels[index].id &&
              tag.name.toLowerCase() == normalized.toLowerCase(),
        )) {
      return false;
    }
    final current = _tagModels[index];
    final updated = current.copyWith(name: normalized);
    await _persist(() => _repository?.saveTag(updated));
    _tagModels[index] = updated;
    _replaceProperties((property) {
      if (!property.tagIds.contains(current.id)) return property;
      return property.copyWith(
        tags: property.tags
            .map((name) => name == oldName ? normalized : name)
            .toList(),
      );
    });
    notifyListeners();
    return true;
  }

  Future<bool> deleteTagOption(String name) async {
    final index = _tagModels.indexWhere((tag) => tag.name == name);
    if (index == -1) return false;
    final tag = _tagModels[index];
    await _persist(() => _repository?.deleteTag(tag.id));
    _tagModels.removeAt(index);
    _replaceProperties((property) {
      if (!property.tagIds.contains(tag.id)) return property;
      final tagIndex = property.tagIds.indexOf(tag.id);
      final ids = List<String>.of(property.tagIds)..removeAt(tagIndex);
      final names = List<String>.of(property.tags);
      if (tagIndex < names.length) names.removeAt(tagIndex);
      return property.copyWith(tagIds: ids, tags: names);
    });
    notifyListeners();
    return true;
  }

  Future<void> reorderTagOptions(int oldIndex, int newIndex) async {
    final updated = List<PropertyTag>.of(_tagModels);
    final tag = updated.removeAt(oldIndex);
    updated.insert(newIndex, tag);
    final normalized = [
      for (var i = 0; i < updated.length; i++)
        updated[i].copyWith(sortOrder: i),
    ];
    await _persist(
      () =>
          _repository?.reorderTags(normalized.map((item) => item.id).toList()),
    );
    _tagModels = normalized;
    notifyListeners();
  }

  Iterable<Property> get _allProperties sync* {
    yield* _properties;
    yield* _trash;
  }

  bool _containsName(List<PropertyArea> areas, String name) =>
      areas.any((area) => area.name.toLowerCase() == name.toLowerCase());

  PropertyType? _typeByName(String name) {
    for (final type in _propertyTypeModels) {
      if (type.name.toLowerCase() == name.toLowerCase()) return type;
    }
    return null;
  }

  PropertyTag? _tagByName(String name) {
    for (final tag in _tagModels) {
      if (tag.name.toLowerCase() == name.toLowerCase()) return tag;
    }
    return null;
  }

  Property _normalizeProperty(Property property) {
    final type = property.propertyTypeId.isNotEmpty
        ? _propertyTypeModels
              .where((item) => item.id == property.propertyTypeId)
              .firstOrNull
        : _typeByName(property.propertyType);
    if (type == null) {
      throw StateError('Loại BĐS không hợp lệ: ${property.propertyType}');
    }

    final resolvedTags = <PropertyTag>[];
    if (property.tagIds.isNotEmpty) {
      for (final id in property.tagIds) {
        final matches = _tagModels.where((tag) => tag.id == id);
        if (matches.isNotEmpty) resolvedTags.add(matches.first);
      }
    } else {
      for (final name in property.tags) {
        final tag = _tagByName(name);
        if (tag != null) resolvedTags.add(tag);
      }
    }

    return property.copyWith(
      propertyTypeId: type.id,
      propertyType: type.name,
      tagIds: resolvedTags.map((tag) => tag.id).toList(),
      tags: resolvedTags.map((tag) => tag.name).toList(),
    );
  }

  Property _hydrateFixtureProperty(Property property) {
    final point = GeoPoint.fromLegacyNormalized(property.mapX, property.mapY);
    return _normalizeProperty(
      property.copyWith(
        latitude: property.latitude ?? point.latitude,
        longitude: property.longitude ?? point.longitude,
      ),
    );
  }

  void _replaceProperties(Property Function(Property) transform) {
    _properties = _properties.map(transform).toList();
    _trash = _trash.map(transform).toList();
  }

  Future<void> _reconcileMedia() async {
    final storage = mediaStorage;
    if (storage == null) return;
    final properties = [..._properties, ..._trash];
    await storage.reconcileAfterStartup(
      propertyIds: properties.map((property) => property.id).toSet(),
      referencedPaths: {
        for (final property in properties)
          for (final photo in property.photos) photo.relativePath,
        for (final property in properties)
          for (final photo in property.photos)
            if (photo.thumbnailRelativePath != null)
              photo.thumbnailRelativePath!,
        for (final property in properties)
          for (final document in property.documents) document.relativePath,
        for (final property in properties)
          for (final document in property.documents)
            if (document.thumbnailRelativePath != null)
              document.thumbnailRelativePath!,
      },
    );
  }

  Future<T?> _persist<T>(Future<T>? Function() operation) async {
    if (_repository != null && !_isInitialized) {
      throw StateError('Dữ liệu ứng dụng chưa sẵn sàng');
    }
    final future = operation();
    if (future == null) return null;
    try {
      _lastError = null;
      return await future;
    } catch (error) {
      _lastError = error;
      notifyListeners();
      rethrow;
    }
  }
}
