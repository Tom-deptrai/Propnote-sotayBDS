/// Các trạng thái entitlement có thể có của PropNote Pro.
enum SubscriptionTier {
  /// Chưa xác định — vừa khởi động app, chưa đọc xong cache/store.
  unknown,

  /// Không có gói Pro active (mặc định, hoặc sau khi hết hạn/huỷ).
  free,

  /// Có gói Pro active (đã mua hoặc restore thành công).
  pro,

  /// Giao dịch mua đang chờ xử lý (vd. chờ phê duyệt gia đình, chờ thanh
  /// toán) — chưa unlock Pro cho tới khi có kết quả cuối cùng.
  pending,

  /// Lỗi khi tải thông tin gói/xử lý giao dịch — không tự suy ra Pro hay
  /// Free, giữ nguyên trạng thái entitlement gần nhất đã biết (xem
  /// [SubscriptionState.tier] khi lỗi xảy ra trong lúc đã có cache).
  error,
}

/// Trạng thái subscription hiện tại, được [SubscriptionService] phát ra và
/// [PropertyQuotaPolicy]/UI tiêu thụ — không phụ thuộc trực tiếp vào
/// StoreKit/Play Billing.
class SubscriptionState {
  final SubscriptionTier tier;

  /// Giá hiển thị đã được store localize sẵn (vd. "199.000 ₫"), null nếu
  /// chưa tải được thông tin sản phẩm. Không bao giờ hard-code giá trong UI
  /// — luôn ưu tiên giá trị này khi có.
  final String? localizedPrice;

  final String? errorMessage;

  const SubscriptionState._({
    required this.tier,
    this.localizedPrice,
    this.errorMessage,
  });

  const SubscriptionState.unknown({String? localizedPrice})
    : this._(tier: SubscriptionTier.unknown, localizedPrice: localizedPrice);

  const SubscriptionState.free({String? localizedPrice})
    : this._(tier: SubscriptionTier.free, localizedPrice: localizedPrice);

  const SubscriptionState.pro({String? localizedPrice})
    : this._(tier: SubscriptionTier.pro, localizedPrice: localizedPrice);

  const SubscriptionState.pending({String? localizedPrice})
    : this._(tier: SubscriptionTier.pending, localizedPrice: localizedPrice);

  const SubscriptionState.error(
    String message, {
    SubscriptionTier fallbackTier = SubscriptionTier.error,
    String? localizedPrice,
  }) : this._(
         tier: fallbackTier,
         errorMessage: message,
         localizedPrice: localizedPrice,
       );

  bool get isPro => tier == SubscriptionTier.pro;

  SubscriptionState copyWithPrice(String? localizedPrice) =>
      SubscriptionState._(
        tier: tier,
        localizedPrice: localizedPrice ?? this.localizedPrice,
        errorMessage: errorMessage,
      );

  @override
  String toString() =>
      'SubscriptionState(tier: $tier, localizedPrice: $localizedPrice, '
      'errorMessage: $errorMessage)';
}
