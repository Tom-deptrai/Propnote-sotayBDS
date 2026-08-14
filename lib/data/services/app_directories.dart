import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Các đường dẫn do ứng dụng kiểm soát. Domain chỉ lưu đường dẫn tương đối
/// tính từ [rootPath] để an toàn khi iOS đổi sandbox sau update/restore.
class AppDirectories {
  final String rootPath;

  AppDirectories._(this.rootPath);

  static Future<AppDirectories> create({String? rootPath}) async {
    final base = rootPath ?? (await getApplicationSupportDirectory()).path;
    final directories = AppDirectories._(p.join(base, 'propnote'));
    await directories.ensureCreated();
    return directories;
  }

  String get dataPath => p.join(rootPath, 'data');
  String get mediaPath => p.join(rootPath, 'media');
  String get propertiesMediaPath => p.join(mediaPath, 'properties');
  String get temporaryPath => p.join(rootPath, 'temporary');
  String get backupsPath => p.join(rootPath, 'backups');
  String get databasePath => p.join(dataPath, 'propnote.sqlite');

  String resolve(String relativePath) {
    final normalized = p.normalize(relativePath);
    if (p.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw ArgumentError.value(relativePath, 'relativePath');
    }
    return p.join(rootPath, normalized);
  }

  String relative(String absolutePath) {
    final normalizedRoot = p.normalize(rootPath);
    final normalizedPath = p.normalize(absolutePath);
    if (!p.isWithin(normalizedRoot, normalizedPath)) {
      throw ArgumentError.value(absolutePath, 'absolutePath');
    }
    return p.relative(normalizedPath, from: normalizedRoot);
  }

  Future<void> ensureCreated() async {
    for (final path in [
      dataPath,
      propertiesMediaPath,
      temporaryPath,
      backupsPath,
    ]) {
      await Directory(path).create(recursive: true);
    }
  }

  Future<int> totalSize() async {
    var total = 0;
    final root = Directory(rootPath);
    if (!await root.exists()) return 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
