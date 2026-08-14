import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/app_runtime.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'utils/app_messenger.dart';
import 'widgets/media_path_scope.dart';
import 'widgets/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _launchProductionApp();
}

Future<void> _launchProductionApp() async {
  try {
    final runtime = await AppRuntime.create();
    runApp(PropNoteApp(appState: runtime.state, runtime: runtime));
  } catch (error) {
    runApp(_StartupErrorApp(error: error));
  }
}

class PropNoteApp extends StatelessWidget {
  final AppState? appState;
  final AppRuntime? runtime;

  const PropNoteApp({super.key, this.appState, this.runtime});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppRuntime?>.value(value: runtime),
        ChangeNotifierProvider<AppState>.value(value: appState ?? AppState()),
      ],
      child: MediaPathScope(
        directories: runtime?.directories,
        child: MaterialApp(
          title: 'PropNote',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootMessengerKey,
          theme: AppTheme.light,
          home: const RootShell(),
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  final Object error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PropNote',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_rounded, size: 44),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể mở dữ liệu PropNote',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _launchProductionApp,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
