import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/app_repository.dart';
import 'subscription_state.dart';

/// Product ID cho gói PropNote Pro theo năm — dùng CHUNG một logical
/// product trên cả iOS (App Store Connect) và Android (Play Console) để
/// giữ entitlement logic đơn giản, không phải rẽ nhánh theo platform.
const String proYearlyProductId = 'propnote_pro_yearly';

const String _entitlementCacheKey = 'subscription_entitlement_cache';
const String _entitlementCachePro = 'pro';

/// Cầu nối duy nhất giữa UI/[PropertyQuotaPolicy] và store purchase API
/// (StoreKit trên iOS, Play Billing trên Android qua package
/// `in_app_purchase`). UI không bao giờ gọi `InAppPurchase` trực tiếp —
/// luôn đi qua service này để sau này có thể thêm server-side receipt
/// verification mà không phải sửa lại UI/quota architecture.
class SubscriptionService extends ChangeNotifier {
  final InAppPurchase _iap;
  final AppRepository? _repository;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  SubscriptionState _state = const SubscriptionState.unknown();
  bool _initialized = false;

  SubscriptionService({InAppPurchase? inAppPurchase, this._repository})
    : _iap = inAppPurchase ?? InAppPurchase.instance;

  SubscriptionState get state => _state;
  ProductDetails? get product => _product;
  bool get isPro => _state.isPro;

  /// Chỉ dùng trong test — set thẳng [state] mà không cần dựng fake
  /// InAppPurchasePlatform đầy đủ, cho các test UI chỉ cần biết entitlement
  /// hiện tại (vd. "Pro user thấy gì"), không cần test lại cơ chế IAP (đã
  /// có subscription_service_test.dart lo phần đó).
  @visibleForTesting
  void debugSetState(SubscriptionState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Khởi tạo service: đọc cache local để có UI ngay lập tức (tránh
  /// "nhấp nháy" về Free trong lúc chờ store trả lời), sau đó tải thông
  /// tin sản phẩm + đăng ký lắng nghe purchase stream + gọi restore để
  /// đối chiếu với trạng thái thật từ store.
  ///
  /// Không throw — mọi lỗi được phản ánh qua [state] (tier `error`) để UI
  /// tự quyết định cách hiển thị, không chặn app khởi động.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final cached = await _readCachedEntitlement();
    if (cached) {
      _state = const SubscriptionState.pro();
      notifyListeners();
    }

    final available = await _iap.isAvailable();
    if (!available) {
      _state = SubscriptionState.error(
        'Cửa hàng ứng dụng hiện không khả dụng.',
        fallbackTier: cached ? SubscriptionTier.pro : SubscriptionTier.free,
      );
      notifyListeners();
      return;
    }

    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _state = SubscriptionState.error(
          error.toString(),
          fallbackTier: _state.tier == SubscriptionTier.pro
              ? SubscriptionTier.pro
              : SubscriptionTier.free,
          localizedPrice: _product?.price,
        );
        notifyListeners();
      },
    );

    await _loadProduct();

    // Đối chiếu entitlement thật từ store. Nếu không có gì để restore,
    // purchaseStream đơn giản là không bắn event nào — không có API nào
    // của in_app_purchase xác nhận "chắc chắn không có purchase" mà không
    // qua receipt server-side, nên nếu chưa có cache Pro, mặc định về Free
    // ngay sau khi phát lệnh restore thay vì treo mãi ở "unknown".
    unawaited(_iap.restorePurchases());
    if (!cached && _state.tier == SubscriptionTier.unknown) {
      _state = SubscriptionState.free(localizedPrice: _product?.price);
      notifyListeners();
    }
  }

  Future<void> _loadProduct() async {
    try {
      final response = await _iap.queryProductDetails({proYearlyProductId});
      if (response.error != null) {
        debugPrint('queryProductDetails error: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'Subscription product not found on store: ${response.notFoundIDs} '
          '— chưa tạo product trên App Store Connect/Play Console?',
        );
      }
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
        _state = _state.copyWithPrice(_product?.price);
        notifyListeners();
      }
    } catch (error) {
      debugPrint('Không tải được thông tin gói Pro: $error');
    }
  }

  /// Bắt đầu luồng mua gói Pro. Kết quả (thành công/lỗi/pending) đến qua
  /// [state] sau khi purchaseStream cập nhật — gọi hàm này không trả về
  /// kết quả mua trực tiếp.
  Future<void> buy() async {
    final product = _product;
    if (product == null) {
      _state = SubscriptionState.error(
        'Không tải được thông tin gói Pro. Vui lòng thử lại.',
        fallbackTier: _state.tier == SubscriptionTier.pro
            ? SubscriptionTier.pro
            : SubscriptionTier.free,
      );
      notifyListeners();
      return;
    }
    _state = SubscriptionState.pending(localizedPrice: product.price);
    notifyListeners();
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      _state = SubscriptionState.error(
        error.toString(),
        fallbackTier: SubscriptionTier.free,
        localizedPrice: product.price,
      );
      notifyListeners();
    }
  }

  /// Khôi phục giao dịch mua đã thực hiện trước đó (đổi thiết bị, cài lại
  /// app). Kết quả cũng đến qua purchaseStream giống [buy].
  Future<void> restore() => _iap.restorePurchases();

  /// Mở trang quản lý subscription của store (Apple/Google) — nơi người
  /// dùng tự huỷ/thay đổi gói, PropNote không tự xử lý việc này.
  Future<void> openManagementUrl() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != proYearlyProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _state = SubscriptionState.pending(localizedPrice: _product?.price);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _state = SubscriptionState.pro(localizedPrice: _product?.price);
          await _writeCachedEntitlement(isPro: true);
        case PurchaseStatus.canceled:
          _state = SubscriptionState.free(localizedPrice: _product?.price);
          await _writeCachedEntitlement(isPro: false);
        case PurchaseStatus.error:
          _state = SubscriptionState.error(
            purchase.error?.message ?? 'Giao dịch không thành công.',
            fallbackTier: SubscriptionTier.free,
            localizedPrice: _product?.price,
          );
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      notifyListeners();
    }
  }

  Future<bool> _readCachedEntitlement() async {
    final value = await _repository?.readSetting(_entitlementCacheKey);
    return value == _entitlementCachePro;
  }

  Future<void> _writeCachedEntitlement({required bool isPro}) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      await repository.writeSetting(
        _entitlementCacheKey,
        isPro ? _entitlementCachePro : 'free',
      );
    } catch (_) {
      // Cache chỉ phục vụ UX khởi động nhanh — lỗi ghi không cần chặn luồng
      // entitlement chính (vốn vẫn đúng nhờ purchaseStream/store).
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
