import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// Kết quả xác minh entitlement từ nguồn đáng tin nhất hiện có trên
/// platform — KHÔNG phải suy luận từ trạng thái `restored`/cache local.
enum EntitlementResult {
  /// Store xác nhận entitlement hiện đang active (chưa hết hạn/chưa bị thu
  /// hồi) tại thời điểm gọi.
  active,

  /// Store xác nhận KHÔNG có entitlement active (hết hạn/bị thu hồi/chưa
  /// từng mua) — khác với [unknown]: đây là câu trả lời chắc chắn.
  notActive,

  /// Không xác minh được theo cách này trên platform/phiên bản hiện tại
  /// (API không hỗ trợ, hoặc lời gọi thất bại) — caller phải rơi về nguồn
  /// tín hiệu khác thay vì coi đây là "notActive" (tránh hạ nhầm Pro thật).
  unknown,
}

/// Xác minh entitlement hiện hành cho 1 product ID, tách khỏi
/// [SubscriptionService] để test được bằng fake thuần Dart (không cần mock
/// platform channel StoreKit2/Play Billing thật).
abstract class EntitlementEvaluator {
  Future<EntitlementResult> currentEntitlement(String productId);
}

/// Dùng `Transaction.all` của StoreKit 2 (qua `in_app_purchase_storekit`) —
/// package `in_app_purchase` cross-platform không expose sẵn API này, và
/// đây là nguồn đáng tin nhất hiện có để biết 1 subscription CÒN ACTIVE hay
/// KHÔNG, thay vì chỉ dựa vào `PurchaseStatus.restored` (StoreKit có thể
/// trả cả giao dịch cũ ĐÃ HẾT HẠN qua `Transaction.all`/restore — xem
/// `SK2Transaction.expirationDate` trong plugin).
///
/// Giới hạn đã biết: plugin hiện tại chỉ expose `Transaction.all` (tương
/// đương lịch sử giao dịch), KHÔNG expose `Transaction.currentEntitlements`
/// trực tiếp — nên phải tự lọc theo [SK2Transaction.expirationDate] của
/// giao dịch MỚI NHẤT (theo purchaseDate) cho đúng product. Nếu Apple/plugin
/// sau này expose `currentEntitlements` thẳng, nên chuyển sang dùng thẳng
/// API đó thay vì tự lọc thủ công như đây.
class StoreKit2EntitlementEvaluator implements EntitlementEvaluator {
  const StoreKit2EntitlementEvaluator();

  @override
  Future<EntitlementResult> currentEntitlement(String productId) async {
    if (!Platform.isIOS) return EntitlementResult.unknown;
    try {
      final transactions = await SK2Transaction.transactions();
      final matching = transactions
          .where((transaction) => transaction.productId == productId)
          .toList();
      if (matching.isEmpty) {
        // Không có giao dịch nào cho product này trong lịch sử — chắc chắn
        // không active, không phải "chưa xác minh được".
        return EntitlementResult.notActive;
      }
      // Mỗi lần gia hạn tạo 1 transaction MỚI (id khác, originalId giữ
      // nguyên) — lấy bản mới nhất theo purchaseDate để có expirationDate
      // đúng chu kỳ hiện tại, không phải chu kỳ cũ đã hết hạn từ lâu.
      matching.sort(
        (a, b) => (int.tryParse(b.purchaseDate) ?? 0).compareTo(
          int.tryParse(a.purchaseDate) ?? 0,
        ),
      );
      final expirationRaw = matching.first.expirationDate;
      if (expirationRaw == null) {
        // Subscription tự gia hạn luôn có expirationDate theo tài liệu
        // StoreKit 2 — null ở đây nghĩa là dữ liệu không như kỳ vọng, an
        // toàn hơn là để caller rơi về fallback thay vì tự đoán còn hạn.
        return EntitlementResult.unknown;
      }
      final expiresAtMs = int.tryParse(expirationRaw);
      if (expiresAtMs == null) return EntitlementResult.unknown;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
      return expiresAt.isAfter(DateTime.now())
          ? EntitlementResult.active
          : EntitlementResult.notActive;
    } catch (error) {
      debugPrint(
        'StoreKit2 entitlement check thất bại — fallback về heuristic '
        'restorePurchases() cũ: $error',
      );
      return EntitlementResult.unknown;
    }
  }
}

/// Dùng khi không có cách xác minh entitlement độc lập với
/// `PurchaseStatus` trên platform hiện tại (Android, hoặc iOS không có
/// StoreKit 2) — [SubscriptionService] tự rơi về heuristic dựa trên
/// `restorePurchases()`/purchaseStream khi gặp [EntitlementResult.unknown].
///
/// Trên Android, heuristic đó vốn đã đáng tin: `restorePurchases()` của
/// `in_app_purchase_android` gọi `BillingClient.queryPurchases(subs)`, theo
/// đúng ngữ nghĩa Play Billing CHỈ trả về purchase người dùng ĐANG SỞ HỮU —
/// subscription đã hết hạn/huỷ (qua khỏi grace period) sẽ không xuất hiện
/// trong kết quả, nên KHÔNG cần 1 evaluator Play Billing riêng.
class NullEntitlementEvaluator implements EntitlementEvaluator {
  const NullEntitlementEvaluator();

  @override
  Future<EntitlementResult> currentEntitlement(String productId) async =>
      EntitlementResult.unknown;
}
