import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:propnote/data/repositories/app_repository.dart';
import 'package:propnote/subscription/subscription_service.dart';
import 'package:propnote/subscription/subscription_state.dart';

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

  SubscriptionService buildService() => SubscriptionService(
    inAppPurchase: InAppPurchase.instance,
    repository: fakeRepository,
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

  test('restore success → Pro', () async {
    fakePlatform.products = [_proProduct()];
    final service = buildService();
    await service.initialize();

    fakePlatform.emit(_purchase(PurchaseStatus.restored));
    await Future<void>.delayed(Duration.zero);

    expect(service.state.tier, SubscriptionTier.pro);
    expect(service.isPro, isTrue);
  });

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
}
