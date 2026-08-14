class BackupManifest {
  static const int currentFormatVersion = 1;

  final int formatVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final String databaseSha256;

  const BackupManifest({
    required this.formatVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.databaseSha256,
  });

  Map<String, Object> toJson() => {
    'formatVersion': formatVersion,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'databaseSha256': databaseSha256,
  };

  factory BackupManifest.fromJson(Map<String, Object?> json) {
    final formatVersion = json['formatVersion'];
    final schemaVersion = json['schemaVersion'];
    final createdAt = json['createdAt'];
    final databaseSha256 = json['databaseSha256'];
    if (formatVersion is! int ||
        schemaVersion is! int ||
        createdAt is! String ||
        databaseSha256 is! String ||
        databaseSha256.length != 64) {
      throw const FormatException('Manifest backup không hợp lệ');
    }
    return BackupManifest(
      formatVersion: formatVersion,
      schemaVersion: schemaVersion,
      createdAt: DateTime.parse(createdAt),
      databaseSha256: databaseSha256,
    );
  }
}
