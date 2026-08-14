import '../../models/area.dart';
import '../../models/property.dart';
import '../../models/property_tag.dart';
import '../../models/property_type.dart';

class AppDataSnapshot {
  final List<Property> properties;
  final List<Property> trash;
  final List<PropertyArea> areas;
  final List<PropertyType> propertyTypes;
  final List<PropertyTag> tags;
  final double markerScale;

  const AppDataSnapshot({
    required this.properties,
    required this.trash,
    required this.areas,
    required this.propertyTypes,
    required this.tags,
    required this.markerScale,
  });
}

class PropertyAssetPaths {
  final String propertyId;
  final List<String> relativePaths;

  const PropertyAssetPaths({
    required this.propertyId,
    required this.relativePaths,
  });
}

abstract interface class AppRepository {
  Future<AppDataSnapshot> loadSnapshot();

  Future<void> saveProperty(Property property);
  Future<void> movePropertyToTrash(String propertyId, DateTime deletedAt);
  Future<void> restoreProperty(String propertyId, DateTime updatedAt);
  Future<PropertyAssetPaths> deletePropertyPermanently(String propertyId);
  Future<List<PropertyAssetPaths>> emptyTrash();

  Future<void> saveArea(PropertyArea area);
  Future<void> deleteArea(String areaId);
  Future<void> reorderAreas(List<String> orderedIds);

  Future<void> savePropertyType(PropertyType type);
  Future<void> deletePropertyType(String typeId);
  Future<void> reorderPropertyTypes(List<String> orderedIds);

  Future<void> saveTag(PropertyTag tag);
  Future<void> deleteTag(String tagId);
  Future<void> reorderTags(List<String> orderedIds);

  Future<String?> readSetting(String key);
  Future<void> writeSetting(String key, String value);
}
