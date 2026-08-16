# PropNote 1.0 — Release Checklist

Bundle/Application ID: `com.propnote.propnote`
iOS Team ID: `VZAHR6GK36`
Subscription product ID (both stores): `propnote_pro_yearly`
Target price (Việt Nam): 199.000đ / năm

Mục này là checklist thao tác — không tự động hoá được các bước cần tài
khoản App Store Connect / Google Play Console, những bước đó được đánh dấu
rõ **[BẠN LÀM]**.

---

## iOS — App Store

### App record & subscription (App Store Connect)

- [ ] **[BẠN LÀM]** Tạo app record trên App Store Connect cho bundle ID
      `com.propnote.propnote` (nếu chưa có).
- [ ] **[BẠN LÀM]** Tạo Subscription Group tên **"PropNote Pro"**.
- [ ] **[BẠN LÀM]** Trong group đó, tạo 1 auto-renewable subscription:
  - Reference name: `PropNote Pro Yearly`
  - Product ID: `propnote_pro_yearly`
  - Duration: 1 năm
  - Price: chọn price tier tương ứng ~199.000đ tại Việt Nam (App Store Connect
    tự quy đổi theo tỷ giá cho các thị trường khác — không cần set thủ công
    từng thị trường).
  - Localization (tối thiểu tiếng Việt): display name "PropNote Pro",
    description ngắn "Không giới hạn số lượng bất động sản".
  - Review screenshot cho subscription (App Store Connect yêu cầu 1 ảnh minh
    hoạ khi submit subscription lần đầu).
- [ ] **[BẠN LÀM]** Đính subscription này vào version App đang submit (mục
      "In-App Purchases and Subscriptions" trong version) để được review cùng
      lượt với app.

### Store listing

- [ ] **[BẠN LÀM]** Screenshots (theo từng kích thước thiết bị App Store yêu
      cầu).
- [ ] **[BẠN LÀM]** App description, keywords, category.
- [ ] **[BẠN LÀM]** Privacy Policy URL công khai (bắt buộc — app hiện chỉ có
      trang Chính sách riêng tư TRONG app, chưa có URL công khai riêng; cần
      host nội dung này ở một URL — nội dung tham khảo:
      `lib/screens/settings/static_info_screen.dart` → `kPrivacyPolicyText`).
- [ ] **[BẠN LÀM]** App Privacy (câu hỏi "Data collected" trên App Store
      Connect) — xem `RELEASE_PRIVACY_NOTES.md` để điền chính xác.

### Code & build

- [x] StoreKit purchase/restore/entitlement code đã tích hợp
      (`lib/subscription/`).
- [x] `flutter build ios --release` — build thành công, ký với Team
      `VZAHR6GK36`.
- [ ] Archive qua Xcode (`open ios/Runner.xcworkspace` → Product → Archive)
      hoặc `xcodebuild archive` để tạo `.xcarchive`, sau đó export IPA.
- [ ] **[BẠN LÀM]** Upload build lên App Store Connect (Xcode Organizer hoặc
      Transporter).
- [ ] **[BẠN LÀM]** Điền Review Notes giải thích subscription cho reviewer
      (vd. tài khoản sandbox nếu cần).
- [ ] **[BẠN LÀM]** Submit App Review.

---

## Android — Google Play

### Production signing **[BLOCKER — BẠN LÀM]**

Chưa có upload keystore production. Trước khi build AAB production:

1. Tạo keystore (một lần duy nhất, giữ an toàn — mất là không update được
   app nữa):
   ```
   keytool -genkey -v -keystore ~/propnote-upload-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias propnote-upload
   ```
2. Tạo `android/key.properties` (đã có trong `.gitignore`, không commit):
   ```
   storePassword=<mật khẩu keystore>
   keyPassword=<mật khẩu key>
   keyAlias=propnote-upload
   storeFile=/đường/dẫn/tuyệt/đối/tới/propnote-upload-key.jks
   ```
3. `android/app/build.gradle.kts` đã được cấu hình sẵn để tự đọc file này —
   không cần sửa gì thêm, `flutter build appbundle --release` sẽ tự ký đúng
   khi `key.properties` tồn tại.

Cho tới khi có bước này, `flutter build apk/appbundle --release` vẫn chạy
được nhưng ký bằng debug key (không hợp lệ để upload Play Console).

### Play Console

- [ ] **[BẠN LÀM]** Tạo app trên Google Play Console (nếu chưa có), package
      name `com.propnote.propnote`.
- [ ] **[BẠN LÀM]** Monetization setup → Products → Subscriptions: tạo
      subscription `propnote_pro_yearly` với 1 base plan `yearly`
      (auto-renewing), giá ~199.000đ tại Việt Nam.
- [ ] **[BẠN LÀM]** Store listing: mô tả, screenshots, category.
- [ ] **[BẠN LÀM]** Data Safety form — xem `RELEASE_PRIVACY_NOTES.md`.
- [ ] **[BẠN LÀM]** Content rating questionnaire.
- [ ] **[BẠN LÀM]** Xác nhận yêu cầu testing hiện tại của tài khoản (tài
      khoản mới thường bắt buộc closed testing với ≥12 tester trong ≥14 ngày
      trước khi mở production — kiểm tra "Publishing overview" trên Play
      Console để biết chính xác yêu cầu áp dụng cho tài khoản này. Nếu có,
      không có cách bypass — cần chạy đủ closed testing track trước.

### Code & build

- [x] Play Billing permission (`com.android.vending.BILLING`) đã thêm vào
      `AndroidManifest.xml`.
- [x] `android/app/build.gradle.kts` đã có signingConfig production
      (tự động dùng khi có `key.properties`, xem trên).
- [ ] Sau khi có keystore: `flutter build appbundle --release` để tạo AAB
      production, upload lên track testing/production tương ứng.

---

## Cả hai nền tảng

- [x] `flutter analyze` sạch.
- [x] `flutter test` — toàn bộ pass (bao gồm test quota + subscription mới).
- [x] App display name chuẩn hoá thành "PropNote" (iOS
      `CFBundleDisplayName`, Android `android:label`).
- [x] Version hiển thị trong Settings đọc từ package metadata thật
      (`package_info_plus`), không hard-code.
- [x] Privacy Policy / Giới thiệu trong app đã cập nhật đúng thực tế sản
      phẩm (không còn nói "UI prototype").
- [ ] Bundle ID / Application ID / Team ID: **không đổi** trong toàn bộ quá
      trình chuẩn bị release này (đã xác nhận giữ nguyên).
