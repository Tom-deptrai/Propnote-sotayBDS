/// Single source of truth cho giới hạn số lượng BĐS trên gói Free.
///
/// Không hard-code số 10 ở bất kỳ màn hình nào khác — luôn đọc qua
/// [PropertyQuotaPolicy.freeLimit] / [PropertyQuotaPolicy.canCreateProperty].
abstract final class PropertyQuotaPolicy {
  static const int freeLimit = 10;

  /// [countedPropertyTotal] phải bao gồm cả BĐS trong Thùng rác — dữ liệu
  /// trong Thùng rác vẫn còn và có thể khôi phục, nên vẫn tính vào quota;
  /// chỉ xoá vĩnh viễn (permanent delete / empty trash) mới giải phóng
  /// quota. Xem [countedPropertyTotalOf] để tính giá trị này từ AppState.
  static bool canCreateProperty({
    required bool isPro,
    required int countedPropertyTotal,
  }) {
    return isPro || countedPropertyTotal < freeLimit;
  }

  /// Số BĐS còn lại có thể tạo trước khi chạm giới hạn Free (0 nếu đã Pro
  /// hoặc đã đạt/vượt giới hạn — dùng cho UI hiển thị, không dùng để gate).
  static int remainingFreeSlots({
    required bool isPro,
    required int countedPropertyTotal,
  }) {
    if (isPro) return 0;
    final remaining = freeLimit - countedPropertyTotal;
    return remaining > 0 ? remaining : 0;
  }
}
