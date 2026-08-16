import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:propnote/data/repositories/app_repository.dart';
import 'package:propnote/subscription/entitlement_evaluator.dart';
import 'package:propnote/subscription/subscription_service.dart';
import 'package:propnote/subscription/subscription_state.dart';

/// Evaluator giả — cho test kiểm soát trực tiếp [EntitlementResult] mà
/// không cần mock platform channel StoreKit2/Play Billing thật (đúng tinh
/// thần "tách entitlement evaluator thành pure/testable abstraction").
class _FakeEntitlementEvaluator implements EntitlementEvaluator {
  _FakeEntitlementEvaluator(this.result);

  EntitlementResult result;
  int callCount = 0;

  @override
  Future<EntitlementResult> currentEntitlement(String productId) async {
    callCount++;
    return result;
  }
}

/// Repository giả tối thiểu — chỉ cài đặt readSetting/writeSetting (dùng
/// cho cache entitlement); mọi thao tác dữ liệu BĐS khác không liên quan
/// tới subscription nên không cần implement, dựa vào `noSuchMethod`.
class _FakeRepository implements AppRepository {
  final Map<String, String> settings = {};

  @override
  Future<String?> readSetting(String key) async => settings[key];

  @override
  Future<void> writeSetting(String key, String value) async {
    settings[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePurchasePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements InAppPurchasePlatform {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  List<ProductDetails> products = [];
  List<String> notFoundIds = [];
  int restoreCallCount = 0;
  int buyCallCount = 0;
  bool throwOnRestore = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: products,
      notFoundIDs: notFoundIds,
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buyCallCount++;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCallCount++;
    if (throwOnRestore) {
      throw StateError('simulated network failure during restore');
    }
  }

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);

  Future<void> dispose() => _controller.close();
}

ProductDetails _proProduct({String price = '199.000 ₫'}) => ProductDetails(
  id: proYearlyProductId,
  title: 'PropNote Pro',
  description: 'Không giới hạn số lượng bất động sản',
  price: price,
  rawPrice: 199000,
  currencyCode: 'VND',
);

PurchaseDetails _purchase(PurchaseStatus status, {String? productId}) =>
    PurchaseDetails(
      productID: productId ?? proYearlyProductId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: DateTime(2026, 8, 16).millisecondsSinceEpoch.toString(),
      status: status,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePurchasePlatform fakePlatform;
  late _FakeRepository fakeRepository;

  setUp(() {
    // InAppPurchase.instance is a process-wide singleton whose *first ever*
    // access auto-registers the real platform plugin (StoreKit/Play
    // Billing) based on defaultTargetPlatform, which would hit a genuine
    // platform channel in the test harness. Overriding to a platform the
    // package doesn't special-case (fuchsia) makes that one-time
    // registration a no-op, so our fake InAppPurchasePlatform below is what
    // every test actually talks to — same trick the package's own tests use.
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    fakePlatform = _FakePurchasePlatform();
    InAppPurchasePlatform.instance = fakePlatform;
    fakeRepository = _FakeRepository();
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await fakePlatform.dispose();
  });

  SubscriptionService buildService({EntitlementEvaluator? entitlementEvaluator}) =>
      SubscriptionService(
        inAppPurchase: InAppPurchase.instance,
        repository: fakeRepository,
        entitlementEvaluator: entitlementEvaluator,
      );

  test('product loaded — state exposes localized price from store', () async {
    fakePlatform.products = [_proProduct(price: '199.000 ₫')];
    final service = buildService();

    await service.initialize();

    expect(service.product?.id, proYearlyProductId);
    expect(service.state.localizedPrice, '199.000 ₫');
  });

  test('purchase success → Pro, and entitlement cached', () async {
    fakePlatform.products = [_proProduct()];
    final service = buildService();
    await service.initialize();
    expect(service.isPro, isFalse);

    fakePlatform.emit(_purchase(PurchaseStatus.purchased));
    await Future<void>.delayed(Duration.zero);

    expect(service.state.tier, SubscriptionTier.pro);
    expect(service.isPro, isTrue);
    expect(fakeRepository.settings['subscription_entitlement_cache'], 'pro');
  });

  test(
    'restore success → Pro (no entitlement evaluator available on this '
    'platform — falls back to trusting the restored signal as-is, same as '
    'production behavior on Android)',
    () async {
      fakePlatform.products = [_proProduct()];
      final service = buildService();
      await service.initialize();

      fakePlatform.emit(_purchase(PurchaseStatus.restored));
      await Future<void>.delayed(Duration.zero);

      expect(service.state.tier, SubscriptionTier.pro);
      expect(service.isPro, isTrue);
    },
  );

  test('pending → chưa unlock Pro', () async {
    fakePlatform.products = [_proProduct()];
    final service = buildService();
    await service.initialize();

    fakePlatform.emit(_purchase(PurchaseStatus.pending));
    await Future<void>.delayed(Duration.zero);

    expect(service.state.tier, SubscriptionTier.pending);
    expect(service.isPro, isFalse);
  });

  test('cancel → Free', () async {
    fakePlatform.products = [_proProduct()];
    final service = buildService();
    await service.initialize();

    fakePlatform.emit(_purchase(PurchaseStatus.canceled));
    await Future<void>.delayed(Duration.zero);

    expect(service.state.tier, SubscriptionTier.free);
    expect(service.isPro, isFalse);
  });

  test('purchase error → Free (with error message attached)', () async {
    fakePlatform.products = [_proProduct()];
    final service = buildService();
    await service.initialize();

    final errorPurchase = _purchase(PurchaseStatus.error)
      ..error = IAPError(
        source: 'test',
        code: 'boom',
        message: 'Giao dịch thất bại',
      );
    fakePlatform.emit(errorPurchase);
    await Future<void>.delayed(Duration.zero);

    expect(service.state.tier, SubscriptionTier.free);
    expect(service.isPro, isFalse);
    expect(service.state.errorMessage, 'Giao dịch thất bại');
  });

  test(
    'subscription inactive (no cache, no restored purchase) → Free after init',
    () async {
      fakePlatform.products = [_proProduct()];
      final service = buildService();

      await service.initialize();
      // restorePurchases() is fired but the fake platform never emits any
      // purchase — with no cache present, the service must not stay stuck
      // at "unknown" forever.
      await Future<void>.delayed(Duration.zero);

      expect(service.state.tier, SubscriptionTier.free);
      expect(service.isPro, isFalse);
      expect(fakePlatform.restoreCallCount, greaterThanOrEqualTo(1));
    },
  );

  test(
    'cached Pro entitlement survives initialize() when store has nothing to '
    'contradict it (no purchase emitted) — avoids the "unknown → default '
    'Free" fallback incorrectly downgrading an already-known Pro user',
    () async {
      fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
      fakePlatform.products = [_proProduct()];
      final service = buildService();

      await service.initialize();

      expect(service.state.tier, SubscriptionTier.pro);
      expect(service.isPro, isTrue);
    },
  );

  test(
    'buy() with no product loaded surfaces an error instead of crashing',
    () async {
      final service = buildService();
      await service.buy();
      expect(service.state.errorMessage, isNotNull);
      expect(service.isPro, isFalse);
    },
  );

  group('entitlement reconciliation hardening', () {
    test(
      'cached Pro + restore completes with no purchase confirmed → '
      'downgrades to Free (subscription actually expired/cancelled since '
      'last launch, but no server verification exists to know that '
      'directly — restorePurchases() silently finding nothing is the only '
      'client-side signal available)',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.products = [_proProduct()];
        final service = buildService();

        await service.initialize();
        expect(service.state.tier, SubscriptionTier.pro);

        // _reconcileEntitlement is unawaited inside initialize() — give it
        // time to call restorePurchases(), wait its internal grace period,
        // and downgrade.
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(service.state.tier, SubscriptionTier.free);
        expect(service.isPro, isFalse);
        expect(fakeRepository.settings['subscription_entitlement_cache'], 'free');
      },
    );

    test(
      'cached Pro + restorePurchases() throws (e.g. offline) → stays Pro, '
      'never downgrades from a failed network request alone',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.products = [_proProduct()];
        fakePlatform.throwOnRestore = true;
        final service = buildService();

        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(service.state.tier, SubscriptionTier.pro);
        expect(service.isPro, isTrue);
      },
    );

    test(
      'cached Pro + store unavailable → stays Pro (no restore attempted at '
      'all, matches existing "store unavailable" fallback)',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.available = false;
        final service = buildService();

        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(service.isPro, isTrue);
      },
    );

    test(
      'no cache but store actually has an active purchase (reinstall/new '
      'device scenario) → restore still runs and picks it up as Pro',
      () async {
        fakePlatform.products = [_proProduct()];
        final service = buildService();

        final initFuture = service.initialize();
        await initFuture;
        // Store "discovers" the restored purchase shortly after restore is
        // requested — simulates a real reinstall where the device has no
        // local cache but the App Store/Play account does have an active
        // subscription.
        fakePlatform.emit(_purchase(PurchaseStatus.restored));
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(service.state.tier, SubscriptionTier.pro);
        expect(service.isPro, isTrue);
        expect(fakePlatform.restoreCallCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'app resume triggers reconciliation again — a cached Pro user whose '
      'subscription lapsed while the app sat in the background gets '
      'downgraded on the next resume, not just at cold start',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.products = [_proProduct()];
        final service = buildService();
        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        // Cold-start reconciliation already ran and found nothing to
        // confirm — state is already Free at this point (covered by the
        // dedicated test above). Reset the fake's call counter and put the
        // cache/state back into an "optimistic Pro" shape as if a fresh
        // cold start just happened, then simulate a resume directly.
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        service.debugSetState(const SubscriptionState.pro());
        final restoreCallsBeforeResume = fakePlatform.restoreCallCount;

        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(
          fakePlatform.restoreCallCount,
          greaterThan(restoreCallsBeforeResume),
        );
        expect(service.state.tier, SubscriptionTier.free);
      },
    );

    test(
      'two overlapping reconciliations (rapid resume) do not both call '
      'restorePurchases — the in-flight guard makes the second call a '
      'no-op instead of double-querying the store',
      () async {
        fakePlatform.products = [_proProduct()];
        final service = buildService();
        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        final callsBefore = fakePlatform.restoreCallCount;

        // Fire resume twice back-to-back with no await between them — the
        // second call must observe _reconcileInFlight already true.
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(fakePlatform.restoreCallCount, callsBefore + 1);
      },
    );
  });

  group('entitlement evaluator overrides the restored heuristic', () {
    test(
      'cached Pro + evaluator confirms notActive → downgrades to Free even '
      'though purchaseStream emitted a restored transaction for the old '
      'product (the exact "old restored transaction but not active" case)',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.products = [_proProduct()];
        final evaluator = _FakeEntitlementEvaluator(EntitlementResult.notActive);
        final service = buildService(entitlementEvaluator: evaluator);
        await service.initialize();
        expect(service.state.tier, SubscriptionTier.pro);

        fakePlatform.emit(_purchase(PurchaseStatus.restored));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(service.state.tier, SubscriptionTier.free);
        expect(service.isPro, isFalse);
        expect(fakeRepository.settings['subscription_entitlement_cache'], 'free');
        expect(evaluator.callCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'cached Pro + evaluator confirms active → stays Pro (restored '
      'transaction is genuinely still valid)',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.products = [_proProduct()];
        final evaluator = _FakeEntitlementEvaluator(EntitlementResult.active);
        final service = buildService(entitlementEvaluator: evaluator);
        await service.initialize();

        fakePlatform.emit(_purchase(PurchaseStatus.restored));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(service.state.tier, SubscriptionTier.pro);
        expect(service.isPro, isTrue);
      },
    );

    test(
      'no cache + evaluator confirms active during reconciliation alone '
      '(no purchaseStream event needed) → becomes Pro — covers reinstall/ '
      'new device with a genuinely active StoreKit2 entitlement',
      () async {
        fakePlatform.products = [_proProduct()];
        final evaluator = _FakeEntitlementEvaluator(EntitlementResult.active);
        final service = buildService(entitlementEvaluator: evaluator);

        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(service.state.tier, SubscriptionTier.pro);
        expect(service.isPro, isTrue);
        expect(
          fakeRepository.settings['subscription_entitlement_cache'],
          'pro',
        );
      },
    );

    test(
      'no cache + evaluator confirms notActive → stays Free', () async {
        fakePlatform.products = [_proProduct()];
        final evaluator = _FakeEntitlementEvaluator(EntitlementResult.notActive);
        final service = buildService(entitlementEvaluator: evaluator);

        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));

        expect(service.state.tier, SubscriptionTier.free);
        expect(service.isPro, isFalse);
      },
    );

    test(
      'evaluator result unknown falls back to the old restorePurchases-only '
      'heuristic unchanged (Android production behavior)',
      () async {
        fakeRepository.settings['subscription_entitlement_cache'] = 'pro';
        fakePlatform.products = [_proProduct()];
        final evaluator = _FakeEntitlementEvaluator(EntitlementResult.unknown);
        final service = buildService(entitlementEvaluator: evaluator);

        await service.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 700));

        // Same fallback as the "no restored purchase" hardening test above:
        // restore completed with nothing confirmed → downgrade.
        expect(service.state.tier, SubscriptionTier.free);
      },
    );
  });

  group('EntitlementEvaluator implementations', () {
    test('NullEntitlementEvaluator always returns unknown', () async {
      const evaluator = NullEntitlementEvaluator();
      expect(
        await evaluator.currentEntitlement(proYearlyProductId),
        EntitlementResult.unknown,
      );
    });
  });
}
