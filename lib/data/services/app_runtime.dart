import '../../state/app_state.dart';
import '../database/app_database.dart';
import '../repositories/app_repository.dart';
import '../repositories/sqlite_app_repository.dart';
import 'app_directories.dart';
import 'backup_service.dart';
import 'location_service.dart';
import 'map_configuration_service.dart';
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
  final bool googleMapsConfigured;
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
    required this.googleMapsConfigured,
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
    final googleMapsConfigured = await const MapConfigurationService()
        .isGoogleMapsConfigured();
    final state = AppState(repository: repository, mediaStorage: mediaStorage);
    await state.initialize();
    return AppRuntime(
      directories: directories,
      database: database,
      repository: repository,
      mediaStorage: mediaStorage,
      locationService: locationService,
      platformActions: platformActions,
      propertyShareService: propertyShareService,
      backupService: backupService,
      googleMapsConfigured: googleMapsConfigured,
      state: state,
    );
  }
}
