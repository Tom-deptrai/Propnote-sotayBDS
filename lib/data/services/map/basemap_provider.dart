import 'map_coverage_policy.dart';

/// Cấu hình font/attribution cho basemap local — lớp cấu hình tập trung duy
/// nhất biết font stack cụ thể mà glyphs cục bộ thực sự phục vụ. Business
/// logic và UI chỉ được phép đọc [BasemapProviders.active] — không hard-code
/// font stack ở bất kỳ đâu khác.
class BasemapProvider {
  final String id;
  final String displayName;
  final String attribution;

  /// Font stack (theo tên thư mục glyphs cục bộ, vd. "Noto Sans Regular")
  /// dùng cho text symbol (label giá, road label...) do app tự vẽ thêm lên
  /// bản đồ. Renderer yêu cầu tên khớp với font stack mà [LocalMapAssetsService]
  /// thực sự copy ra đĩa — nếu không, chữ sẽ không hiển thị dù layer vẫn
  /// được tạo thành công (không có lỗi rõ ràng nào được ném ra).
  final List<String> textFontNames;

  const BasemapProvider({
    required this.id,
    required this.displayName,
    required this.attribution,
    this.textFontNames = const ['Noto Sans Regular'],
  });
}

/// Provider bản đồ đang active cho toàn app — bundle local PMTiles cho
/// TP.HCM + Hà Nội (xem [MapCoveragePolicy]), không dùng basemap
/// live/remote nào (không OpenFreeMap, không fallback online).
abstract final class BasemapProviders {
  static const localPmtiles = BasemapProvider(
    id: 'local-pmtiles',
    displayName: 'PropNote Local Map',
    attribution: '© OpenMapTiles © OpenStreetMap contributors',
  );

  static const BasemapProvider active = localPmtiles;
}

/// Style JSON MapLibre production-oriented cho app khảo sát BĐS: giữ
/// roads/street labels/buildings/water/parks/POI, bỏ boundary chính trị
/// (không có source-layer nào tham chiếu 'boundary'). Road label tách 2 tier
/// (trục chính minzoom 11 / đường nhỏ minzoom 12) với symbol-spacing +
/// text-size theo zoom để tên đường lặp lại hợp lý dọc đường dài — kiến trúc
/// đã kiểm chứng PASS qua POC (`propnote_thu_nghiem`).
///
/// Layer `coverage-mask-fill` được đặt CUỐI CÙNG (vẽ đè lên tất cả layer
/// khác) — bắt buộc vì lưới tile của Planetiler snap theo ô tile chuẩn,
/// không khớp tuyệt đối với bbox tuỳ ý khai báo lúc extract dữ liệu, nên dữ
/// liệu thật (vd. nước) có thể "rò" ra vài mét ngoài rìa bbox; đặt mask ở vị
/// trí cuối đảm bảo phần ngoài [region] luôn hiện nền xám sạch, không rò rỉ,
/// bất kể z-order của các layer khác. Marker/label do app tự vẽ (SymbolManager/
/// runtime overlay) luôn nằm trên layer cuối cùng của style theo mặc định
/// của MapLibre nên không bị mask che.
Map<String, dynamic> buildLocalMapStyle({
  required SupportedMapRegion region,
  required String pmtilesUrl,
  required String glyphsTemplate,
}) {
  final fontstack = BasemapProviders.active.textFontNames.first;
  return {
    'version': 8,
    'name': 'PropNote Local Style — ${region.displayName}',
    'sources': {
      'openmaptiles': {'type': 'vector', 'url': pmtilesUrl},
      'coverage-mask': {
        'type': 'geojson',
        'data': _coverageMaskGeoJson(region),
      },
    },
    'glyphs': glyphsTemplate,
    'layers': [
      {
        'id': 'background',
        'type': 'background',
        'paint': {'background-color': '#f2efe9'},
      },
      {
        'id': 'water',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'water',
        'paint': {'fill-color': '#a0c8f0'},
      },
      {
        'id': 'landcover_wood',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'landcover',
        'filter': [
          '==',
          ['get', 'class'],
          'wood',
        ],
        'paint': {'fill-color': '#c8dcb4'},
      },
      {
        'id': 'landcover_grass',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'landcover',
        'filter': [
          '==',
          ['get', 'class'],
          'grass',
        ],
        'paint': {'fill-color': '#d6e8bf'},
      },
      {
        'id': 'park',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'park',
        'paint': {'fill-color': '#c8e6c0'},
      },
      {
        'id': 'building',
        'type': 'fill',
        'source': 'openmaptiles',
        'source-layer': 'building',
        'minzoom': 13,
        'paint': {'fill-color': '#d9d0c9', 'fill-outline-color': '#c2b8ad'},
      },
      {
        'id': 'waterway',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'waterway',
        'paint': {'line-color': '#a0c8f0', 'line-width': 1.0},
      },
      {
        'id': 'road_minor',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
        'minzoom': 11,
        'filter': [
          'in',
          ['get', 'class'],
          ['literal', ['minor', 'service', 'path', 'track']],
        ],
        'paint': {
          'line-color': '#ffffff',
          'line-width': [
            'interpolate', ['linear'], ['zoom'],
            11, 0.4,
            14, 1.0,
            18, 2.6,
          ],
        },
      },
      {
        'id': 'road_major',
        'type': 'line',
        'source': 'openmaptiles',
        'source-layer': 'transportation',
        'filter': [
          'in',
          ['get', 'class'],
          [
            'literal',
            ['primary', 'secondary', 'tertiary', 'trunk', 'motorway'],
          ],
        ],
        'paint': {
          'line-color': '#f4a95c',
          'line-width': [
            'interpolate', ['linear'], ['zoom'],
            9, 0.6,
            12, 1.6,
            16, 3.2,
            18, 5.0,
          ],
        },
      },
      {
        'id': 'road_label_major',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'transportation_name',
        'minzoom': 11,
        'filter': [
          'in',
          ['get', 'class'],
          ['literal', ['motorway', 'trunk', 'primary', 'secondary']],
        ],
        'layout': {
          'symbol-placement': 'line',
          'symbol-spacing': [
            'interpolate', ['linear'], ['zoom'],
            11, 480,
            14, 320,
            18, 200,
          ],
          'text-field': ['get', 'name'],
          'text-font': [fontstack],
          'text-size': [
            'interpolate', ['linear'], ['zoom'],
            11, 10.0,
            14, 12.0,
            18, 15.0,
          ],
          'text-max-angle': 30,
          'text-letter-spacing': 0.02,
        },
        'paint': {
          'text-color': '#4a3a1a',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1.2,
        },
      },
      {
        'id': 'road_label_minor',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'transportation_name',
        'minzoom': 12,
        'filter': [
          '!in',
          ['get', 'class'],
          ['literal', ['motorway', 'trunk', 'primary', 'secondary']],
        ],
        'layout': {
          'symbol-placement': 'line',
          'symbol-spacing': [
            'interpolate', ['linear'], ['zoom'],
            12, 300,
            14, 220,
            16, 160,
            18, 110,
          ],
          'text-field': ['get', 'name'],
          'text-font': [fontstack],
          'text-size': [
            'interpolate', ['linear'], ['zoom'],
            12, 9.5,
            14, 10.5,
            16, 11.5,
            18, 13.0,
          ],
          'text-max-angle': 40,
        },
        'paint': {
          'text-color': '#5a5a5a',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1.0,
        },
      },
      {
        'id': 'poi_label',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'poi',
        'minzoom': 15,
        'layout': {
          'text-field': ['get', 'name'],
          'text-font': [fontstack],
          'text-size': 10.0,
          'text-anchor': 'top',
          'text-offset': [0.0, 0.8],
        },
        'paint': {
          'text-color': '#7a5a3a',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1.0,
        },
      },
      {
        'id': 'place_label_city',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'place',
        'filter': [
          'in',
          ['get', 'class'],
          ['literal', ['city', 'town']],
        ],
        'layout': {
          'text-field': ['get', 'name'],
          'text-font': [fontstack],
          'text-size': [
            'interpolate', ['linear'], ['zoom'],
            9, 12.0,
            13, 16.0,
          ],
        },
        'paint': {
          'text-color': '#2a2a2a',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1.4,
        },
      },
      {
        'id': 'place_label_other',
        'type': 'symbol',
        'source': 'openmaptiles',
        'source-layer': 'place',
        'minzoom': 12,
        'filter': [
          '!in',
          ['get', 'class'],
          ['literal', ['city', 'town']],
        ],
        'layout': {
          'text-field': ['get', 'name'],
          'text-font': [fontstack],
          'text-size': 11.0,
        },
        'paint': {
          'text-color': '#3a3a3a',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1.1,
        },
      },
      {
        'id': 'coverage-mask-fill',
        'type': 'fill',
        'source': 'coverage-mask',
        'paint': {'fill-color': '#c9c9c9', 'fill-opacity': 1.0},
      },
    ],
  };
}

/// GeoJSON polygon-với-lỗ dùng làm mask "nền xám ngoài coverage": vành ngoài
/// phủ gần hết thế giới, vành trong (lỗ) đúng bằng bbox của [region] — bên
/// trong lỗ không bị tô (layer thật hiển thị bình thường qua đó), bên ngoài
/// lỗ bị tô xám. 100% local, không cần network.
Map<String, dynamic> _coverageMaskGeoJson(SupportedMapRegion region) {
  return {
    'type': 'Feature',
    'properties': {},
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [-179.9, -85.0],
          [179.9, -85.0],
          [179.9, 85.0],
          [-179.9, 85.0],
          [-179.9, -85.0],
        ],
        [
          [region.west, region.south],
          [region.west, region.north],
          [region.east, region.north],
          [region.east, region.south],
          [region.west, region.south],
        ],
      ],
    },
  };
}
