import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:propnote/data/services/app_runtime.dart';
import 'package:propnote/screens/add_property/add_property_screen.dart';
import 'package:propnote/models/property.dart';
import 'package:propnote/models/property_status.dart';
import 'package:propnote/state/app_state.dart';
import 'package:propnote/subscription/property_quota_policy.dart';
import 'package:propnote/subscription/subscription_service.dart';
import 'package:propnote/subscription/subscription_state.dart';
import 'package:propnote/theme/app_theme.dart';
import 'package:propnote/widgets/root_shell.dart';

Property _propertyAt(AppState state, String id) {
  final now = DateTime(2026, 8, 16);
  final type = state.propertyTypeModels.first;
  return Property(
    id: id,
    title: 'BĐS $id',
    address: 'BĐS $id',
    areaId: state.areas.first.id,
    status: PropertyStatus.selling,
    price: 1e9,
    landArea: 50,
    propertyTypeId: type.id,
    propertyType: type.name,
    createdAt: now,
  );
}

Future<void> _fillToFreeLimit(AppState state) async {
  while (state.properties.length + state.trash.length <
      PropertyQuotaPolicy.freeLimit) {
    final id = 'quota-${state.properties.length + state.trash.length}';
    await state.addProperty(_propertyAt(state, id));
  }
}

Widget _buildApp({
  required AppState appState,
  required SubscriptionService subscription,
}) {
  return MultiProvider(
    providers: [
      Provider<AppRuntime?>.value(value: null),
      ChangeNotifierProvider<AppState>.value(value: appState),
      ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const RootShell()),
  );
}

void main() {
  testWidgets('App launch shows the map, not the paywall', (tester) async {
    final state = AppState();
    final subscription = SubscriptionService();

    await tester.pumpWidget(
      _buildApp(appState: state, subscription: subscription),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bản đồ'), findsOneWidget);
    expect(find.text('Nâng cấp lên Pro'), findsNothing);
    expect(find.text('PropNote Pro'), findsNothing);
  });

  testWidgets(
    'Free user at the 10-property limit: tapping + opens the paywall, not '
    'the Add Property form',
    (tester) async {
      final state = AppState();
      await _fillToFreeLimit(state);
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Thêm bất động sản'), findsNothing);
      expect(find.text('PropNote Pro'), findsOneWidget);
      expect(find.text('Không giới hạn số lượng bất động sản'), findsOneWidget);
      // Quota-reached context (mục 5): phải giải thích rõ tại sao paywall
      // xuất hiện, đúng wording — "10 BĐS" (không phải "10 lượt lưu"), có
      // nhắc Thùng rác, có "xoá vĩnh viễn", có "không giới hạn".
      expect(
        find.textContaining('Bạn đã dùng hết 10 BĐS của gói Free'),
        findsOneWidget,
      );
      expect(find.textContaining('Thùng rác'), findsOneWidget);
      expect(find.textContaining('Xoá vĩnh viễn'), findsOneWidget);
    },
  );

  testWidgets(
    'Voluntary upgrade from Settings does NOT show the quota-reached '
    'message, even when the user happens to be at/under the free limit',
    (tester) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Cài đặt'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Nâng cấp lên Pro'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Không giới hạn số lượng bất động sản'), findsOneWidget);
      expect(
        find.textContaining('Bạn đã dùng hết 10 BĐS'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Quota-reached paywall triggered from the defensive save-time gate '
    '(quota already over the limit when Save is pressed) also shows the '
    'quota-reached message, not the bare voluntary-upgrade one',
    (tester) async {
      final state = AppState();
      await _fillToFreeLimit(state);
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppRuntime?>.value(value: null),
            ChangeNotifierProvider<AppState>.value(value: state),
            ChangeNotifierProvider<SubscriptionService>.value(
              value: subscription,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const AddPropertyScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Cần điền tên trước, nếu không nút Lưu chỉ hiện snackbar báo thiếu
      // tên chứ chưa chạm tới cổng quota.
      await tester.enterText(find.byType(TextField).first, 'BĐS test quota');
      await tester.scrollUntilVisible(
        find.text('Lưu bất động sản'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Lưu bất động sản'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Giá/diện tích/vị trí chưa điền → dialog xác nhận "Bổ sung"/"Vẫn
      // lưu" xuất hiện trước — chọn "Vẫn lưu" để tới được cổng quota.
      final proceedAnyway = find.text('Vẫn lưu');
      if (proceedAnyway.evaluate().isNotEmpty) {
        await tester.tap(proceedAnyway);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      expect(
        find.textContaining('Bạn đã dùng hết 10 BĐS của gói Free'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Pro user at/over the 10-property limit: tapping + opens the Add '
      'Property form directly, no paywall', (tester) async {
    final state = AppState();
    await _fillToFreeLimit(state);
    final subscription = SubscriptionService()
      ..debugSetState(const SubscriptionState.pro());

    await tester.pumpWidget(
      _buildApp(appState: state, subscription: subscription),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Thêm bất động sản'), findsOneWidget);
    expect(find.text('PropNote Pro'), findsNothing);
  });

  testWidgets(
    'Settings shows the Free upgrade card by default, and the active-Pro '
    'card once entitlement is Pro',
    (tester) async {
      final state = AppState();
      final subscription = SubscriptionService();

      await tester.pumpWidget(
        _buildApp(appState: state, subscription: subscription),
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Cài đặt'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nâng cấp lên Pro'), findsOneWidget);
      expect(find.text('Đang sử dụng gói Pro'), findsNothing);

      subscription.debugSetState(const SubscriptionState.pro());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nâng cấp lên Pro'), findsNothing);
      expect(find.text('Đang sử dụng gói Pro'), findsOneWidget);
      expect(find.text('Quản lý đăng ký'), findsOneWidget);
    },
  );
}
