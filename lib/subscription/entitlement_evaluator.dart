import 'dart:convert' show jsonDecode;
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

/// Cờ revoked/upgraded đọc được từ [SK2Transaction.jsonRepresentation] —
/// `null` nghĩa là KHÔNG xác định được (JSON không có/không parse được),
/// khác với `false` (xác định được và KHÔNG revoked/upgraded). Tách riêng
/// khỏi [StoreKit2EntitlementEvaluator] để test thuần Dart với chuỗi JSON
/// mẫu, không cần platform channel thật.
typedef RevocationFlags = ({bool? isRevoked, bool? isUpgraded});

/// Đọc `revocationDate`/`isUpgraded` từ `jsonRepresentation` của 1
/// [SK2Transaction] — 2 field này KHÔNG được plugin `in_app_purchase_storekit`
/// expose thành field Dart riêng trên [SK2Transaction] (đã kiểm tra trực
/// tiếp source `sk2_transaction_wrapper.dart` phiên bản 0.4.11+1: class chỉ
/// có id/originalId/productId/purchaseDate/expirationDate/quantity/
/// appAccountToken/subscriptionGroupID/price/error/receiptData/
/// jsonRepresentation — không có revocationDate/isUpgraded riêng).
///
/// `jsonRepresentation` chính là `Transaction.jsonRepresentation` gốc của
/// Apple, truyền NGUYÊN VĂN qua bridge native — đã kiểm tra trực tiếp
/// `StoreKit2Translators.swift` (`darwin/.../StoreKit2/
/// StoreKit2Translators.swift`, hàm `Transaction.convertToPigeon`):
/// `jsonRepresentation: String(decoding: jsonRepresentation, as: UTF8.self)`
/// — không lược/đổi tên field nào. Theo tài liệu Apple, property này trả
/// dữ liệu "in the same format that App Store Server API and App Store
/// Server Notifications use" — cùng schema `JWSTransactionDecodedPayload`
/// mà Apple đã công bố công khai (bao gồm `revocationDate`,
/// `revocationReason`, `isUpgraded` — đều optional, chỉ xuất hiện khi áp
/// dụng). Đây KHÔNG phải suy đoán định dạng — dựa trên schema Apple công
/// bố + xác nhận bridge không biến đổi gì.
///
/// Nếu JSON không có/không parse được (vd. iOS cũ trả format khác, hoặc lỗi
/// bất ngờ), trả `null` cho field tương ứng — KHÔNG suy đoán, để caller tự
/// quyết định fallback.
///
/// Public (không phải `_private`) + [visibleForTesting] có chủ đích: đây là
/// phần LOGIC THUẦN của evaluator (parse JSON, không đụng platform channel)
/// — test trực tiếp bằng chuỗi JSON mẫu thay vì phải mock StoreKit2 thật.
@visibleForTesting
RevocationFlags parseRevocationFlags(String? jsonRepresentation) {
  if (jsonRepresentation == null) {
    return (isRevoked: null, isUpgraded: null);
  }
  try {
    final decoded = jsonDecode(jsonRepresentation);
    if (decoded is! Map<String, dynamic>) {
      return (isRevoked: null, isUpgraded: null);
    }
    // revocationDate chỉ xuất hiện (khác null) khi giao dịch thực sự bị
    // Apple thu hồi/hoàn tiền — không có key hoặc null nghĩa là chưa revoke.
    final hasRevocationDate = decoded['revocationDate'] != null;
    final isUpgradedRaw = decoded['isUpgraded'];
    return (
      isRevoked: hasRevocationDate,
      isUpgraded: isUpgradedRaw is bool ? isUpgradedRaw : null,
    );
  } catch (error) {
    debugPrint('Không parse được jsonRepresentation của SK2Transaction: $error');
    return (isRevoked: null, isUpgraded: null);
  }
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
/// trực tiếp — nên phải tự lọc theo [SK2Transaction.expirationDate] +
/// revoked/upgraded (qua [parseRevocationFlags]) của giao dịch MỚI NHẤT
/// (theo purchaseDate) cho đúng product, trong số các giao dịch CHƯA bị
/// revoke/upgrade. Nếu Apple/plugin sau này expose `currentEntitlements`
/// thẳng, nên chuyển sang dùng thẳng API đó thay vì tự lọc thủ công như
/// đây. Nếu `jsonRepresentation` không có/không parse được cho 1 giao dịch,
/// giao dịch đó KHÔNG bị loại chỉ vì thiếu dữ liệu revoked/upgraded — chỉ
/// loại khi xác định được CHẮC CHẮN là revoked/upgraded.
class StoreKit2EntitlementEvaluator implements EntitlementEvaluator {
  const StoreKit2EntitlementEvaluator();

  @override
  Future<EntitlementResult> currentEntitlement(String productId) async {
    if (!Platform.isIOS) return EntitlementResult.unknown;
    try {
      final transactions = await SK2Transaction.transactions();
      final candidates = transactions
          .where((transaction) => transaction.productId == productId)
          .where((transaction) {
            final flags = parseRevocationFlags(transaction.jsonRepresentation);
            if (flags.isRevoked == true) return false;
            if (flags.isUpgraded == true) return false;
            return true;
          })
          .toList();
      if (candidates.isEmpty) {
        // Hoặc chưa từng mua product này, hoặc mọi giao dịch tìm được đều
        // đã bị revoke/upgrade — cả 2 trường hợp đều chắc chắn không active.
        return EntitlementResult.notActive;
      }
      // Mỗi lần gia hạn tạo 1 transaction MỚI (id khác, originalId giữ
      // nguyên) — lấy bản mới nhất theo purchaseDate để có expirationDate
      // đúng chu kỳ hiện tại, không phải chu kỳ cũ đã hết hạn từ lâu.
      candidates.sort(
        (a, b) => (int.tryParse(b.purchaseDate) ?? 0).compareTo(
          int.tryParse(a.purchaseDate) ?? 0,
        ),
      );
      final expirationRaw = candidates.first.expirationDate;
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
