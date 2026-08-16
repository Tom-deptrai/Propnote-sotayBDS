# App Store Connect — Subscription Setup

Đúng những gì cần nhập cho `propnote_pro_yearly` (khớp
`proYearlyProductId` trong `lib/subscription/subscription_service.dart`).

## 1. Subscription Group

```
Reference Name:  PropNote Pro
```

Chỉ cần 1 group duy nhất — app hiện chỉ có 1 gói (yearly), không có nhiều
mức giá/thời hạn để so sánh trong cùng group.

## 2. Subscription (trong group trên)

```
Reference Name:   PropNote Pro Yearly
Product ID:       propnote_pro_yearly
Subscription Duration: 1 Year
```

**QUAN TRỌNG:** Product ID phải khớp CHÍNH XÁC chuỗi
`propnote_pro_yearly` — đây là hằng số `proYearlyProductId` hard-code
trong code (`lib/subscription/subscription_service.dart:15`), sai 1 ký tự
sẽ khiến app không tìm thấy sản phẩm (paywall hiện "Chưa thể tải thông tin
gói Pro. Vui lòng thử lại sau.").

## 3. Localization — Vietnamese (vi)

```
Display Name: PropNote Pro
Description:  Lưu không giới hạn số lượng bất động sản.
```

## 4. Localization — English (US) (đề xuất, không bắt buộc)

```
Display Name: PropNote Pro
Description:  Save unlimited properties.
```

## 5. Pricing

Target Việt Nam: khoảng **199.000₫/năm**. Chọn price tier gần nhất với
199.000₫ trong bảng giá App Store Connect hiện hành (Apple tự quy đổi
sang các thị trường khác theo tier đã chọn — không tự set giá tuyệt đối
cho từng quốc gia).

**Lưu ý:** app hiển thị giá LOCALIZED THẬT từ store (`service.state
.localizedPrice`, đọc qua `queryProductDetails`), không hard-code
"199.000₫" ở đâu trong code — do đó số tiền hiển thị trên paywall sẽ tự
động khớp đúng với giá bạn cấu hình ở đây, không cần sửa code sau khi đổi
giá trên App Store Connect.

## 6. Review Information (cho subscription)

- **Review Screenshot**: App Store Connect yêu cầu 1 screenshot minh hoạ
  màn hình subscription — dùng ảnh chụp màn hình Paywall (xem
  `SCREENSHOT_PLAN.md`), kích thước theo yêu cầu hiện hành của Console lúc
  upload.
- **Review Notes** cho riêng subscription (nếu Console hỏi tách biệt, dùng
  đúng nội dung tương ứng trong `APP_REVIEW_NOTES.md`).

## 7. Thứ tự submit quan trọng

- Subscription **đầu tiên** (`propnote_pro_yearly`) BẮT BUỘC phải được
  đính kèm (attach) vào ĐÚNG version 1.0 submission đầu tiên của app — App
  Store không cho phép app có auto-renewable subscription submit version
  đầu tiên mà không kèm ít nhất 1 subscription.
- Trình tự khuyến nghị: tạo App → tạo Subscription Group + Subscription
  (mục 1-5 ở trên) → tạo version 1.0 → điền metadata → **Attach
  subscription vào version 1.0** (mục "In-App Purchases and Subscriptions"
  của version) → submit.

## 8. Đối chiếu lại code hiện tại (đã audit, không cần sửa)

- `lib/subscription/subscription_service.dart`: `proYearlyProductId =
  'propnote_pro_yearly'` — khớp đúng mục 2.
- `buy()` gọi `_iap.buyNonConsumable(...)` — đúng flow chuẩn cho
  auto-renewable subscription qua package `in_app_purchase`.
- `restore()` + nút "Khôi phục giao dịch mua" trên paywall — đã có sẵn,
  không cần thêm gì.
- `openManagementUrl()` mở
  `https://apps.apple.com/account/subscriptions` trên iOS — đúng trang
  quản lý subscription chuẩn của Apple.
