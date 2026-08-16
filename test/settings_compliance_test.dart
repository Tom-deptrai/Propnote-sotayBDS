import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propnote/data/services/app_runtime.dart';
import 'package:propnote/screens/settings/settings_screen.dart';
import 'package:propnote/screens/settings/static_info_screen.dart';
import 'package:propnote/screens/settings/support_screen.dart';
import 'package:propnote/state/app_state.dart';
import 'package:propnote/subscription/subscription_service.dart';
import 'package:propnote/theme/app_theme.dart';

Widget _buildApp({required AppState appState, required SubscriptionService subscription}) {
  return MultiProvider(
    providers: [
      Provider<AppRuntime?>.value(value: null),
      ChangeNotifierProvider<AppState>.value(value: appState),
      ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const SettingsScreen()),
  );
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  group('Settings screen compliance tiles', () {
    testWidgets('shows Privacy, Terms, and Support tiles', (tester) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await _scrollToText(tester, 'Hỗ trợ & liên hệ');

      expect(find.text('Chính sách riêng tư'), findsOneWidget);
      expect(find.text('Điều khoản sử dụng'), findsOneWidget);
      expect(find.text('Hỗ trợ & liên hệ'), findsOneWidget);
    });

    testWidgets('Privacy Policy has retention/deletion + revoke + contact, no placeholder', (
      tester,
    ) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await _scrollToText(tester, 'Chính sách riêng tư');

      await tester.tap(find.text('Chính sách riêng tư'));
      await tester.pumpAndSettle();

      expect(find.byType(StaticInfoScreen), findsOneWidget);
      expect(find.textContaining('Lưu giữ và xoá dữ liệu'), findsOneWidget);
      expect(find.textContaining('thu hồi'), findsOneWidget);
      expect(find.textContaining('Timeforwork789@icloud.com'), findsOneWidget);
      expect(find.textContaining('CẦN ĐIỀN'), findsNothing);
      expect(find.textContaining('[EMAIL'), findsNothing);
    });

    testWidgets('Terms of Use keeps yearly auto-renew subscription semantics', (
      tester,
    ) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await _scrollToText(tester, 'Điều khoản sử dụng');

      await tester.tap(find.text('Điều khoản sử dụng'));
      await tester.pumpAndSettle();

      expect(find.byType(StaticInfoScreen), findsOneWidget);
      expect(find.textContaining('theo năm'), findsOneWidget);
      expect(find.textContaining('tự động gia hạn'), findsOneWidget);
      expect(find.textContaining('Khôi phục giao dịch mua'), findsOneWidget);
    });

    testWidgets('Support screen shows the exact support email and send button', (
      tester,
    ) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await _scrollToText(tester, 'Hỗ trợ & liên hệ');

      await tester.tap(find.text('Hỗ trợ & liên hệ'));
      await tester.pumpAndSettle();

      expect(find.byType(SupportScreen), findsOneWidget);
      expect(find.text(kSupportEmail), findsOneWidget);
      expect(find.text('Gửi email hỗ trợ'), findsOneWidget);
    });

    testWidgets('storage tile falls back to placeholder when runtime is null', (
      tester,
    ) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Dung lượng đang sử dụng'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });
  });
}
