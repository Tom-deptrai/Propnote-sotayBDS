import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_directories.dart';

/// Kết quả tính dung lượng do PropNote chủ động tạo ra trên thiết bị.
class StorageUsage {
  final int appDataBytes;
  final int mapBytes;

  const StorageUsage({required this.appDataBytes, required this.mapBytes});

  int get totalBytes => appDataBytes + mapBytes;
}

/// Tính dung lượng 2 thư mục PropNote kiểm soát: dữ liệu app
/// ([AppDirectories.rootPath]) và bản đồ offline đã copy ra đĩa
/// (thư mục `map` cùng cấp, xem `LocalMapAssetsService._ensureMapDir`).
/// Không tính asset bên trong app bundle, cache hệ thống, hay backup mà
/// user đã tự chia sẻ ra ngoài sandbox.
class StorageUsageService {
  final String appDataRoot;
  final String mapRoot;

  const StorageUsageService({required this.appDataRoot, required this.mapRoot});

  factory StorageUsageService.forDirectories(AppDirectories directories) {
    final supportRoot = p.dirname(directories.rootPath);
    return StorageUsageService(
      appDataRoot: directories.rootPath,
      mapRoot: p.join(supportRoot, 'map'),
    );
  }

  Future<StorageUsage> compute() async {
    final sizes = await Future.wait([
      directorySize(appDataRoot),
      directorySize(mapRoot),
    ]);
    return StorageUsage(appDataBytes: sizes[0], mapBytes: sizes[1]);
  }

  /// Cộng dồn kích thước mọi file trong [path] (đệ quy). Không throw khi
  /// thiếu thư mục, khi 1 file biến mất giữa lúc list và lúc đọc length,
  /// hay khi 1 subdirectory không đọc được (permission) — các entity lỗi
  /// bị bỏ qua, phần còn lại vẫn được cộng đúng thay vì làm hỏng cả phép
  /// tính.
  static Future<int> directorySize(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return 0;
    var total = 0;
    final entities = dir
        .list(recursive: true, followLinks: false)
        .handleError((Object _) {});
    await for (final entity in entities) {
      if (entity is! File) continue;
      try {
        total += await entity.length();
      } on FileSystemException {
        continue;
      }
    }
    return total;
  }
}

String formatStorageBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(2)} GB';
}
