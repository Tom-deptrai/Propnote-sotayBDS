import 'dart:async';

import '../../state/app_state.dart';
import '../../subscription/subscription_service.dart';
import '../database/app_database.dart';
import '../repositories/app_repository.dart';
import '../repositories/sqlite_app_repository.dart';
import 'app_directories.dart';
import 'backup_service.dart';
import 'location_service.dart';
import 'media_storage.dart';
import 'platform_action_service.dart';
import 'property_share_service.dart';

/// Các dependency production dùng chung trong vòng đời ứng dụng.
class AppRuntime {
  final AppDirectories directories;
  final AppDatabase database;
  final AppRepository repository;
  final MediaStorage mediaStorage;
  final LocationService locationService;
  final PlatformActionService platformActions;
  final PropertyShareService propertyShareService;
  final BackupService backupService;
  final SubscriptionService subscriptionService;
  final AppState state;

  const AppRuntime({
    required this.directories,
    required this.database,
    required this.repository,
    required this.mediaStorage,
    required this.locationService,
    required this.platformActions,
    required this.propertyShareService,
    required this.backupService,
    required this.subscriptionService,
    required this.state,
  });

  static Future<AppRuntime> create() async {
    final directories = await AppDirectories.create();
    final database = AppDatabase(directories: directories);
    final repository = SqliteAppRepository(database);
    final mediaStorage = MediaStorage(directories: directories);
    const locationService = LocationService();
    const platformActions = PlatformActionService();
    final propertyShareService = PropertyShareService(directories);
    final backupService = BackupService(
      directories: directories,
      database: database,
    );
    final subscriptionService = SubscriptionService(repository: repository);
    final state = AppState(repository: repository, mediaStorage: mediaStorage);
    await state.initialize();
    final runtime = AppRuntime(
      directories: directories,
      database: database,
      repository: repository,
      mediaStorage: mediaStorage,
      locationService: locationService,
      platformActions: platformActions,
      propertyShareService: propertyShareService,
      backupService: backupService,
      subscriptionService: subscriptionService,
      state: state,
    );
    await runtime.reconcileMedia();
    // Không await: gọi store (network) không được chặn app khởi động —
    // UI đọc SubscriptionState.unknown/cache trong lúc chờ, tự cập nhật
    // qua ChangeNotifier khi có kết quả.
    unawaited(subscriptionService.initialize());
    return runtime;
  }

  Future<void> reconcileMedia() async {
    final properties = [...state.properties, ...state.trash];
    await mediaStorage.reconcileAfterStartup(
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
}
