import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'utils/app_messenger.dart';
import 'widgets/root_shell.dart';

void main() {
  runApp(const PropNoteApp());
}

class PropNoteApp extends StatelessWidget {
  const PropNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'PropNote',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootMessengerKey,
        theme: AppTheme.light,
        home: const RootShell(),
      ),
    );
  }
}
