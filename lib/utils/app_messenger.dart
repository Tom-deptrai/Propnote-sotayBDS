import 'package:flutter/material.dart';

/// Global messenger key so confirmation toasts can survive a screen pop
/// (e.g. showing "Đã lưu bất động sản" after returning to the previous
/// screen), without needing that screen's own BuildContext.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(String message) {
  rootMessengerKey.currentState?.hideCurrentSnackBar();
  rootMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}
