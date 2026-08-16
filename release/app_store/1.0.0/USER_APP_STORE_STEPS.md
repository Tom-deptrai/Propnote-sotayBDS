# Checklist — Các bước bạn cần tự làm trên App Store Connect

Claude đã chuẩn bị sẵn code, build, archive, và toàn bộ nội dung cần thiết
(xem các file trong `release/app_store/1.0.0/`). Dưới đây CHỈ còn những
bước cần tài khoản Apple Developer/2FA/App Store Connect UI của bạn — theo
đúng thứ tự A → H.

---

## A. Apple Developer / Agreements

- [ ] **A1.** Đăng nhập [App Store Connect](https://appstoreconnect.apple.com)
  bằng Apple ID gắn với Team `VZAHR6GK36`.
- [ ] **A2.** Vào **Agreements, Tax, and Banking** — xác nhận:
  - Paid Applications Agreement: **Active**
  - Banking: đã điền
  - Tax forms: đã hoàn tất
  `MANUAL APP STORE CONNECT CHECK` — không thể kiểm tra từ máy local,
  cần bạn tự xác nhận trong Console. Đây là điều kiện bắt buộc để
  subscription hoạt động (app free vẫn cần Agreement active nếu có IAP).

## B. App record

- [ ] **B1.** My Apps → **+ → New App**, điền đúng:

  | Field | Giá trị |
  |---|---|
  | Platform | iOS |
  | Name | `PropNote` |
  | Primary Language | Vietnamese |
  | Bundle ID | `com.propnote.propnote` (tạo Identifier trước trong Certificates, Identifiers & Profiles nếu chưa có) |
  | SKU | `propnote-ios-1` (nội bộ, không hiển thị công khai) |

## C. Subscription

- [ ] **C1.** Tạo Subscription Group + subscription theo đúng
  `SUBSCRIPTION_SETUP.md` (Product ID `propnote_pro_yearly`, duration
  1 Year, ~199.000₫/năm, localization vi + en-US).

## D. URLs / Metadata / Privacy

- [ ] **D1.** Bật GitHub Pages (1 thao tác, ~1-2 phút deploy):
  Repo `Tom-deptrai/Propnote-sotayBDS` → **Settings → Pages** → Source:
  **Deploy from a branch** → Branch: **main**, folder **/docs** → **Save**.
  File đã commit sẵn tại `main:/docs/` (index/privacy/terms/support.html).
  URL sau khi bật (cố định, không cần đoán):
  ```
  https://tom-deptrai.github.io/Propnote-sotayBDS/privacy.html
  https://tom-deptrai.github.io/Propnote-sotayBDS/terms.html
  https://tom-deptrai.github.io/Propnote-sotayBDS/support.html
  ```
- [ ] **D2.** Điền metadata theo `APP_STORE_METADATA_VI.md` — copy-paste
  App Name/Subtitle/Description/Keywords/Category/Copyright/Release Notes.
  Dán 2 URL từ D1 vào **Support URL** và **Privacy Policy URL**. Marketing
  URL để trống. Xem mục "Terms of Use (EULA)" trong file để chọn Apple
  Standard EULA hoặc URL `terms.html`.
- [ ] **D3.** Điền App Privacy theo `APP_PRIVACY_FORM_GUIDE.md` — đối
  chiếu từng dòng `VERIFY IN CURRENT APP STORE CONNECT FORM` với wording
  thật trong Console lúc điền.

## E. Xcode Upload

- [ ] **E1.** Mở **Xcode → Window → Organizer** (Xcode đang mở sẵn).
- [ ] **E2.** Tab **Archives** → chọn `PropNote-1.0.0-build2.xcarchive`
  (nếu không thấy, **File → Open** và trỏ tới
  `build/appstore/PropNote-1.0.0-build2.xcarchive`).
  Dùng bản **build2** (không phải bản `PropNote-1.0.0.xcarchive` cũ hơn).
- [ ] **E3.** **Distribute App → App Store Connect → Upload** →
  **Automatically manage signing** (cần Apple ID Team `VZAHR6GK36` đã
  đăng nhập trong Xcode → Settings → Accounts — đã xác nhận sẵn sàng, xem
  báo cáo chính).
  *Lưu ý: đây là bước duy nhất Claude không kiểm chứng được đúng 100%
  wording UI hiện tại của Xcode 26.6 (không có công cụ đọc màn hình Xcode
  trong phiên này) — nếu tên nút/menu khác với trên, làm theo đúng UI bạn
  thấy, luồng tổng thể (Organizer → Archives → Distribute App → App Store
  Connect → Upload) không đổi qua các bản Xcode gần đây.*
- [ ] **E4.** Build xuất hiện trong App Store Connect sau vài phút–~1 giờ.

## F. Screenshots

- [ ] **F1.** Đã có sẵn 3 ảnh sạch tại
  `release/app_store/1.0.0/screenshots_raw/` (bản đồ TP.HCM, Cài đặt, bản
  đồ Hà Nội — xem `SCREENSHOT_PLAN.md`).
- [ ] **F2.** Tự chụp thêm 4 ảnh còn lại (Danh sách có dữ liệu, Chi tiết
  BĐS, Bản đồ có marker+giá, Add/Edit đã điền) — cần gõ tay 2-3 BĐS mẫu
  bằng tiếng Việt có dấu trực tiếp trên Simulator/thiết bị (công cụ tự
  động của Claude không gõ được dấu tiếng Việt). Xem dữ liệu mẫu đề xuất
  trong `SCREENSHOT_PLAN.md`.
- [ ] **F3.** Upload đủ bộ ảnh theo đúng kích thước Console yêu cầu tại
  thời điểm upload.

## G. Attach build + subscription

- [ ] **G1.** Vào version 1.0 → mục **Build** → chọn build vừa upload
  (bước E).
- [ ] **G2.** Mục **In-App Purchases and Subscriptions** của version 1.0
  → **Attach** subscription `propnote_pro_yearly` — BẮT BUỘC vì đây là
  subscription đầu tiên của app.

## H. Submit

- [ ] **H1.** Paste nguyên khối **FINAL PASTE BLOCK** trong
  `APP_REVIEW_NOTES.md` vào ô **Notes** của App Review Information.
- [ ] **H2.** Rà lại toàn bộ mục A-G đã tick đủ → **Submit for Review**.

---

**Claude sẽ KHÔNG tự động thực hiện bất kỳ bước nào ở trên** (đăng nhập
tài khoản, bật GitHub Pages, submit review) trừ khi bạn yêu cầu cụ thể ở
phiên làm việc riêng.
