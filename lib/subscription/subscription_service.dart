import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/app_repository.dart';
import 'entitlement_evaluator.dart';
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
///
/// ## Entitlement KHÔNG được suy từ `PurchaseStatus.restored` đơn thuần
///
/// `PurchaseStatus.restored` chỉ có nghĩa "store có 1 giao dịch khớp product
/// này trong lịch sử" — trên iOS, `Transaction.all`/cơ chế restore CÓ THỂ
/// trả cả giao dịch ĐÃ HẾT HẠN (subscription cũ không gia hạn nữa), nên
/// KHÔNG được coi `restored == đang active`. [_entitlementEvaluator]
/// ([StoreKit2EntitlementEvaluator] trên iOS) xác minh thêm qua
/// `expirationDate` của giao dịch mới nhất trước khi tin — xem
/// [_applyRestoredTransaction]/[_reconcileEntitlement].
///
/// Trên Android, `restorePurchases()` gọi `queryPurchases(subs)` của Play
/// Billing — theo đúng thiết kế của Play Billing, API này CHỈ trả về
/// purchase người dùng ĐANG SỞ HỮU (subscription hết hạn/huỷ sau grace
/// period sẽ không xuất hiện), nên `restored` trên Android vốn đã là tín
/// hiệu đáng tin — không cần evaluator riêng, xem [NullEntitlementEvaluator].
///
/// ## Giới hạn còn lại (client-side-only, không backend ở 1.0)
///
/// Cả StoreKit2 lẫn Play Billing đều không đẩy thông báo hết hạn về app
/// đang chạy NỀN theo thời gian thực — phát hiện hết hạn chỉ xảy ra ở lần
/// mở/resume kế tiếp (xem [didChangeAppLifecycleState]), không phải ngay
/// lúc hết hạn. Nếu store/mạng lỗi lúc đối chiếu, service GIỮ NGUYÊN trạng
/// thái hiện tại thay vì suy diễn hết hạn từ 1 request thất bại — thà lỡ 1
/// lần chưa hạ kịp còn hơn hạ nhầm 1 user Pro thật vì mạng chập chờn. Nếu
/// cần độ chính xác/real-time cao hơn nữa, cần server-side receipt
/// verification (App Store Server API / Play Developer API + RTDN) ở phase
/// sau — KHÔNG dựng trong bản này.
class SubscriptionService extends ChangeNotifier with WidgetsBindingObserver {
  final InAppPurchase _iap;
  final AppRepository? _repository;
  final EntitlementEvaluator _entitlementEvaluator;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _product;
  SubscriptionState _state = const SubscriptionState.unknown();
  bool _initialized = false;

  /// true khi đã tải xong (query hoàn tất) nhưng KHÔNG tìm thấy sản phẩm
  /// trên store (vd. `propnote_pro_yearly` chưa được tạo trên App Store
  /// Connect/Play Console) hoặc query lỗi — phân biệt với "đang tải"
  /// (product == null && !productUnavailable) để paywall không hiện spinner
  /// vô hạn khi thực ra không còn gì để chờ. Xem [PaywallScreen].
  bool _productUnavailable = false;

  /// true ngay khi purchaseStream thực sự emit ÍT NHẤT 1 giao dịch khớp
  /// [proYearlyProductId] (bất kể trạng thái) — phân biệt "store đã xác
  /// nhận điều gì đó" với "vẫn chỉ đang hiện giá trị cache lạc quan lúc
  /// khởi động, chưa được store xác nhận lại". Chỉ dùng làm FALLBACK khi
  /// [_entitlementEvaluator] trả [EntitlementResult.unknown] — xem
  /// [_reconcileEntitlement].
  bool _entitlementConfirmedByStore = false;

  /// Chặn 2 lần reconciliation chạy chồng nhau (vd. app resume liên tục,
  /// hoặc resume ngay sau khi initialize() vẫn đang tự chạy lần đầu) — mỗi
  /// lần chỉ 1 reconciliation thực sự gọi restorePurchases()/evaluator,
  /// tránh spam store API.
  bool _reconcileInFlight = false;

  SubscriptionService({
    InAppPurchase? inAppPurchase,
    this._repository,
    EntitlementEvaluator? entitlementEvaluator,
  }) : _iap = inAppPurchase ?? InAppPurchase.instance,
       _entitlementEvaluator =
           entitlementEvaluator ??
           (Platform.isIOS
               ? const StoreKit2EntitlementEvaluator()
               : const NullEntitlementEvaluator());

  SubscriptionState get state => _state;
  ProductDetails? get product => _product;
  bool get isPro => _state.isPro;
  bool get productUnavailable => _productUnavailable && _product == null;

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
    WidgetsBinding.instance.addObserver(this);

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

    if (!cached && _state.tier == SubscriptionTier.unknown) {
      // Chưa từng có cache Pro nào — không có entitlement lạc quan nào để
      // đối chiếu, mặc định Free ngay (không cần chờ restore) để UI không
      // treo ở "unknown".
      _state = SubscriptionState.free(localizedPrice: _product?.price);
      notifyListeners();
    }

    // Đối chiếu entitlement thật từ store — xem giới hạn/logic chi tiết ở
    // doc comment của class và [_reconcileEntitlement].
    unawaited(_reconcileEntitlement());
  }

  /// Gọi lại khi app quay lại foreground — bắt các trường hợp subscription
  /// hết hạn/bị huỷ TRONG LÚC app đang ở background (StoreKit/Play Billing
  /// không tự đẩy thông báo hết hạn về app đang chạy nền) — lần mở/resume
  /// kế tiếp sẽ tự đối chiếu lại, xem giới hạn ở doc comment của class.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      unawaited(_reconcileEntitlement());
    }
  }

  /// Đối chiếu entitlement với trạng thái thật từ store qua
  /// [InAppPurchase.restorePurchases] + [_entitlementEvaluator] — xem giới
  /// hạn chi tiết ở doc comment của class. LUÔN gọi restore bất kể cache
  /// hiện tại: đây là cách DUY NHẤT client-side phát hiện đúng 1 user Pro
  /// thật nhưng KHÔNG có cache local (cài lại app/đổi thiết bị). Guard
  /// [_reconcileInFlight] chặn 2 lần chạy chồng (vd. resume liên tục).
  ///
  /// Quyết định cuối theo [EntitlementResult] từ evaluator — KHÔNG còn suy
  /// từ việc purchaseStream có emit `restored` hay không:
  /// - [EntitlementResult.active]: chắc chắn Pro (kể cả không có cache cũ —
  ///   ca cài lại app/đổi máy).
  /// - [EntitlementResult.notActive]: chắc chắn Free — GHI ĐÈ mọi cache Pro
  ///   lạc quan, kể cả khi purchaseStream vừa emit `restored` cho 1 giao
  ///   dịch cũ đã hết hạn.
  /// - [EntitlementResult.unknown] (Android, hoặc iOS không hỗ trợ
  ///   StoreKit2): rơi về heuristic cũ — chỉ hạ Pro lạc quan xuống Free khi
  ///   restore THỰC SỰ hoàn tất (không lỗi/timeout) mà purchaseStream vẫn
  ///   không xác nhận giao dịch nào phù hợp; nếu restore lỗi/timeout, GIỮ
  ///   NGUYÊN trạng thái hiện tại, không suy diễn hết hạn từ 1 request mạng
  ///   thất bại.
  Future<void> _reconcileEntitlement() async {
    if (_reconcileInFlight) return;
    _reconcileInFlight = true;
    try {
      final hadOptimisticPro = _state.tier == SubscriptionTier.pro;
      _entitlementConfirmedByStore = false;
      try {
        await _iap.restorePurchases().timeout(const Duration(seconds: 8));
      } catch (error) {
        debugPrint('Đối chiếu subscription qua restorePurchases thất bại '
            '(giữ nguyên entitlement hiện tại, không suy diễn hết hạn từ lỗi '
            'mạng): $error');
        return;
      }
      // Cho purchaseStream một khoảng ngắn để các event (nếu có) kịp truyền
      // tới — Future của restorePurchases() hoàn tất không đảm bảo mọi
      // event stream tương ứng đã propagate xong trên mọi platform.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final result = await _entitlementEvaluator.currentEntitlement(
        proYearlyProductId,
      );
      switch (result) {
        case EntitlementResult.active:
          if (_state.tier != SubscriptionTier.pro) {
            _state = SubscriptionState.pro(localizedPrice: _product?.price);
            await _writeCachedEntitlement(isPro: true);
            notifyListeners();
          }
        case EntitlementResult.notActive:
          if (_state.tier == SubscriptionTier.pro) {
            _state = SubscriptionState.free(localizedPrice: _product?.price);
            await _writeCachedEntitlement(isPro: false);
            notifyListeners();
          }
        case EntitlementResult.unknown:
          if (hadOptimisticPro &&
              !_entitlementConfirmedByStore &&
              _state.tier == SubscriptionTier.pro) {
            _state = SubscriptionState.free(localizedPrice: _product?.price);
            await _writeCachedEntitlement(isPro: false);
            notifyListeners();
          }
      }
    } finally {
      _reconcileInFlight = false;
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
        _productUnavailable = false;
        _state = _state.copyWithPrice(_product?.price);
      } else {
        // Query đã hoàn tất nhưng không có sản phẩm nào — đây là kết quả
        // CUỐI CÙNG, không phải "đang tải", nên phải báo cho UI biết để
        // dừng hiện spinner (xem [productUnavailable]).
        _productUnavailable = true;
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Không tải được thông tin gói Pro: $error');
      _productUnavailable = true;
      notifyListeners();
    }
  }

  /// Thử tải lại thông tin sản phẩm — dùng cho nút "Thử lại" trên paywall
  /// khi [productUnavailable] là true.
  Future<void> retryLoadProduct() => _loadProduct();

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

  /// `PurchaseStatus.restored` KHÔNG tự động nghĩa "đang active" (xem doc
  /// comment class) — xác minh thêm qua [_entitlementEvaluator] trước khi
  /// commit Pro, thay vì tin thẳng theo trạng thái restored như trước.
  Future<void> _applyRestoredTransaction() async {
    final result = await _entitlementEvaluator.currentEntitlement(
      proYearlyProductId,
    );
    switch (result) {
      case EntitlementResult.active:
      case EntitlementResult.unknown:
        // unknown (Android, hoặc iOS không có StoreKit2): tin theo tín hiệu
        // restored như trước — trên Android tín hiệu đó vốn đã đáng tin,
        // xem [NullEntitlementEvaluator].
        _state = SubscriptionState.pro(localizedPrice: _product?.price);
        await _writeCachedEntitlement(isPro: true);
      case EntitlementResult.notActive:
        _state = SubscriptionState.free(localizedPrice: _product?.price);
        await _writeCachedEntitlement(isPro: false);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != proYearlyProductId) continue;
      // Store đã thực sự nói gì đó về sản phẩm này (bất kể trạng thái) —
      // đánh dấu để [_reconcileEntitlement] biết đây không còn là cache lạc
      // quan chưa được xác nhận nữa.
      _entitlementConfirmedByStore = true;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _state = SubscriptionState.pending(localizedPrice: _product?.price);
        case PurchaseStatus.purchased:
          // Giao dịch MỚI vừa hoàn tất trong phiên này — không mơ hồ, luôn
          // hợp lệ ngay, khác với `restored` (có thể là giao dịch cũ đã hết
          // hạn, xem [_applyRestoredTransaction]).
          _state = SubscriptionState.pro(localizedPrice: _product?.price);
          await _writeCachedEntitlement(isPro: true);
        case PurchaseStatus.restored:
          await _applyRestoredTransaction();
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
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
