import '../../state/app_state.dart';
import '../database/app_database.dart';
import '../repositories/app_repository.dart';
import '../repositories/sqlite_app_repository.dart';
import 'app_directories.dart';

/// Các dependency production dùng chung trong vòng đời ứng dụng.
class AppRuntime {
  final AppDirectories directories;
  final AppDatabase database;
  final AppRepository repository;
  final AppState state;

  const AppRuntime({
    required this.directories,
    required this.database,
    required this.repository,
    required this.state,
  });

  static Future<AppRuntime> create() async {
    final directories = await AppDirectories.create();
    final database = AppDatabase(directories: directories);
    final repository = SqliteAppRepository(database);
    final state = AppState(repository: repository);
    await state.initialize();
    return AppRuntime(
      directories: directories,
      database: database,
      repository: repository,
      state: state,
    );
  }
}
