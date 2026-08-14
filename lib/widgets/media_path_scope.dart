import 'package:flutter/widgets.dart';

import '../data/services/app_directories.dart';

class MediaPathScope extends InheritedWidget {
  final AppDirectories? directories;

  const MediaPathScope({
    super.key,
    required this.directories,
    required super.child,
  });

  static String? resolve(BuildContext context, String? relativePath) {
    if (relativePath == null) return null;
    final scope = context.dependOnInheritedWidgetOfExactType<MediaPathScope>();
    return scope?.directories?.resolve(relativePath);
  }

  @override
  bool updateShouldNotify(MediaPathScope oldWidget) =>
      directories?.rootPath != oldWidget.directories?.rootPath;
}
