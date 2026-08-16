import 'package:flutter_test/flutter_test.dart';
import 'package:propnote/data/services/map/basemap_provider.dart';
import 'package:propnote/data/services/map/map_coverage_policy.dart';

// Mục 14: attribution phải khai báo TƯỜNG MINH trên style JSON — không chỉ
// dựa vào suy luận mặc định của control MapLibre — và phải đúng cho MỌI vùng
// (HCM lẫn Hà Nội), vì mỗi vùng build style JSON riêng.
void main() {
  test(
    'buildLocalMapStyle declares the OpenMapTiles/OSM attribution string '
    'explicitly on the vector source for every SupportedMapRegion',
    () {
      for (final region in MapCoveragePolicy.allRegions) {
        final style = buildLocalMapStyle(
          region: region,
          pmtilesUrl: 'pmtiles://file:///fake/${region.id}.pmtiles',
          glyphsTemplate: 'file:///fake/{fontstack}/{range}.pbf',
        );
        final source = style['sources']['openmaptiles'] as Map;
        expect(
          source['attribution'],
          BasemapProviders.active.attribution,
          reason: 'missing/incorrect attribution for region ${region.id}',
        );
        expect(source['attribution'], contains('OpenStreetMap'));
      }
    },
  );
}
