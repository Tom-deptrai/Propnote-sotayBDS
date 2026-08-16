import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'map_coverage_policy.dart';

/// Copy PMTiles + fonts từ asset bundle của Flutter ra thư mục ghi được thật
/// trên thiết bị — asset bundle không phải đường dẫn filesystem trực tiếp
/// truy cập được từ native code, nên MapLibre style JSON (pmtiles://file://,
/// glyphs file://) cần bản copy thật trên đĩa. 100% local — không có request
/// mạng nào trong toàn bộ quá trình này.
///
/// Kết quả copy được cache lại kèm version app (qua `.version` sidecar nhỏ)
/// để: (a) không phải copy lại file PMTiles nặng (~50MB) mỗi lần mở app, (b)
/// vẫn tự động re-copy đúng lúc nếu 1 bản cập nhật app sau này thay đổi nội
/// dung PMTiles/fonts cùng tên file — tránh cache "đứng hình" ở nội dung cũ
/// khi user chỉ update app (không gỡ cài đặt, nên Application Support
/// directory vẫn còn nguyên qua các lần update trên iOS).
class LocalMapAssetsService {
  Directory? _mapDir;
  String? _appVersionMarker;
  final Map<String, String> _pmtilesUrlByRegionId = {};
  String? _glyphsTemplate;

  Future<Directory> _ensureMapDir() async {
    final existing = _mapDir;
    if (existing != null) return existing;
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/map');
    await dir.create(recursive: true);
    _mapDir = dir;
    return dir;
  }

  Future<String> _currentAppVersionMarker() async {
    final cached = _appVersionMarker;
    if (cached != null) return cached;
    final info = await PackageInfo.fromPlatform();
    final marker = '${info.version}+${info.buildNumber}';
    _appVersionMarker = marker;
    return marker;
  }

  /// [versionFile] chỉ được ghi SAU KHI [target] đã ghi xong hoàn toàn (xem
  /// [_copyAssetToFile]) — tự nó đã là 1 "commit marker": nếu app bị kill
  /// giữa lúc copy target (file PMTiles ~50MB có thể mất >0), versionFile
  /// sẽ KHÔNG tồn tại ở lần mở tiếp theo, nên hàm này trả true (cần copy
  /// lại) và ghi đè file dở dang đó — tự phục hồi mà không cần logic dọn
  /// dẹp riêng cho trường hợp "app bị kill giữa chừng".
  Future<bool> _needsCopy(File target, File versionFile) async {
    if (!await target.exists() || await target.length() == 0) return true;
    if (!await versionFile.exists()) return true;
    final storedMarker = await versionFile.readAsString();
    return storedMarker != await _currentAppVersionMarker();
  }

  /// Ghi ATOMIC: copy ra file TẠM trong CÙNG thư mục với [target] rồi
  /// `rename()` đè lên [target] — rename trong cùng thư mục là 1 syscall
  /// nguyên tử ở cả iOS/Android, nên [target] không bao giờ ở trạng thái
  /// "đang ghi dở" mà vẫn được coi là tồn tại — mạnh hơn cơ chế tự phục hồi
  /// qua [versionFile] (xem doc comment ở đó) chứ không thay thế nó: 2 lớp
  /// bảo vệ độc lập cho cùng 1 rủi ro "app bị kill giữa chừng khi copy".
  Future<void> _copyAssetToFile(
    String assetPath,
    File target,
    File versionFile,
  ) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final tempFile = File('${target.path}.tmp-${DateTime.now().microsecondsSinceEpoch}');
    await tempFile.writeAsBytes(bytes, flush: true);
    await tempFile.rename(target.path);
    await versionFile.writeAsString(
      await _currentAppVersionMarker(),
      flush: true,
    );
  }

  /// Copy 3 range glyph PBF dùng chung cho mọi vùng — trả về glyphs URL
  /// template MapLibre style cần (`file://.../{fontstack}/{range}.pbf`).
  Future<String> ensureGlyphsTemplate() async {
    final cached = _glyphsTemplate;
    if (cached != null) return cached;
    final mapDir = await _ensureMapDir();
    final fontsDir = Directory('${mapDir.path}/fonts/Noto Sans Regular');
    await fontsDir.create(recursive: true);
    for (final range in ['0-255', '256-511', '7680-7935']) {
      final target = File('${fontsDir.path}/$range.pbf');
      final versionFile = File('${fontsDir.path}/$range.pbf.version');
      if (await _needsCopy(target, versionFile)) {
        await _copyAssetToFile(
          'assets/map/fonts/Noto Sans Regular/$range.pbf',
          target,
          versionFile,
        );
      }
    }
    final fontsRootDir = Directory('${mapDir.path}/fonts');
    final template = 'file://${fontsRootDir.path}/{fontstack}/{range}.pbf';
    _glyphsTemplate = template;
    return template;
  }

  /// Copy PMTiles của [region] nếu chưa có/đã lỗi thời — trả về
  /// `pmtiles://file://...` URL dùng làm `source.url` trong style JSON.
  Future<String> ensureRegionPmtilesUrl(SupportedMapRegion region) async {
    final cached = _pmtilesUrlByRegionId[region.id];
    if (cached != null) return cached;
    final mapDir = await _ensureMapDir();
    final target = File('${mapDir.path}/${region.pmtilesAssetFileName}');
    final versionFile = File(
      '${mapDir.path}/${region.pmtilesAssetFileName}.version',
    );
    if (await _needsCopy(target, versionFile)) {
      await _copyAssetToFile(region.pmtilesAssetPath, target, versionFile);
    }
    final url = 'pmtiles://file://${target.path}';
    _pmtilesUrlByRegionId[region.id] = url;
    return url;
  }
}
