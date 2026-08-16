# Checklist — Các bước bạn cần tự làm trên App Store Connect

Claude đã chuẩn bị sẵn code, build, archive, và toàn bộ nội dung cần thiết
(xem các file trong `release/app_store/1.0.0/`). Dưới đây là những bước
CHỈ bạn mới làm được (cần tài khoản Apple Developer/2FA/App Store Connect
UI) — theo đúng thứ tự nên làm.

---

- [ ] **1. Đăng nhập [App Store Connect](https://appstoreconnect.apple.com)**
  bằng tài khoản Apple Developer gắn với Team `VZAHR6GK36`.

- [ ] **2. Tạo New App**
  - Platform: iOS
  - Name: `PropNote`
  - Primary Language: Vietnamese
  - Bundle ID: chọn `com.propnote.propnote` (phải đã đăng ký sẵn trong
    Certificates, Identifiers & Profiles — nếu chưa có, tạo Identifier
    trước với đúng Bundle ID này).
  - SKU: đề xuất `propnote-ios-1` (hoặc bất kỳ chuỗi nội bộ nào bạn muốn,
    không hiển thị công khai).

- [ ] **3. Tạo Subscription Group + `propnote_pro_yearly`**
  Theo đúng `SUBSCRIPTION_SETUP.md` trong cùng thư mục — copy chính xác
  Product ID, duration, giá, mô tả tiếng Việt.

- [ ] **4. Host `privacy-policy.html` công khai**
  Theo `PRIVACY_POLICY_PUBLISH_INSTRUCTIONS.md` — cách nhanh nhất là
  GitHub Pages, chỉ mất ~5 phút. Nhớ điền email hỗ trợ thật vào file HTML
  trước khi publish.

- [ ] **5. Điền metadata theo `APP_STORE_METADATA_VI.md`**
  Copy-paste trực tiếp: App Name, Subtitle, Description, Keywords,
  Category, Copyright, Release Notes. Điền 3 placeholder còn thiếu:
  Support URL, Privacy Policy URL (từ bước 4), và Marketing URL nếu muốn.

- [ ] **6. Upload screenshots**
  Theo `SCREENSHOT_PLAN.md` — cần bạn tự chụp (hoặc yêu cầu Claude chụp ở
  phiên làm việc riêng) theo đúng kích thước App Store Connect yêu cầu tại
  thời điểm upload.

- [ ] **7. Điền App Privacy theo `APP_PRIVACY_FORM_GUIDE.md`**
  Đối chiếu từng mục trong bảng — với các dòng ghi `VERIFY IN CURRENT APP
  STORE CONNECT FORM`, đọc đúng câu hỏi hiện tại trong Console trước khi
  chọn đáp án (form có thể đổi wording theo thời gian).

- [ ] **8. Upload/select build**
  - Nếu bạn tự export IPA qua Xcode Organizer (xem hướng dẫn ngay dưới) và
    upload bằng Transporter/Xcode: build sẽ tự xuất hiện trong danh sách
    "Build" của version 1.0 sau khi xử lý xong (thường vài phút tới ~1
    giờ).
  - Chọn đúng build vừa upload cho version 1.0.

- [ ] **9. Attach subscription `propnote_pro_yearly` vào version 1.0**
  Trong mục "In-App Purchases and Subscriptions" của chính version 1.0 —
  BẮT BUỘC vì đây là subscription đầu tiên của app, không thể submit
  version 1.0 mà thiếu bước này (xem thêm mục 7 trong
  `SUBSCRIPTION_SETUP.md`).

- [ ] **10. Paste Review Notes**
  Copy nguyên khối text trong `APP_REVIEW_NOTES.md` (phần trong dấu
  code block) vào ô "Notes" của App Review Information.

- [ ] **11. Submit for Review**
  Bấm submit khi đã hoàn tất tất cả các mục trên.

---

## Export IPA từ archive đã build sẵn

Claude đã tạo sẵn archive tại:
```
build/appstore/PropNote-1.0.0.xcarchive
```

Máy hiện tại **chưa có Apple Distribution certificate** (chỉ có Development
certificate), nên Claude **không tự export được IPA** — export cần đăng
nhập Xcode với tài khoản Apple Developer của bạn để Xcode tự cấp
Distribution certificate + provisioning profile.

Cách export (chỉ mất 2-3 phút với Xcode Organizer):

1. Mở **Xcode** → menu **Window → Organizer**.
2. Tab **Archives**, chọn `PropNote-1.0.0.xcarchive` (nếu không thấy, dùng
   **File → Open** rồi trỏ tới đường dẫn ở trên).
3. Bấm **Distribute App** → chọn **App Store Connect** → **Upload**.
4. Xcode sẽ tự động quản lý signing (Automatically manage signing) nếu bạn
   đã đăng nhập Apple ID có quyền trên Team `VZAHR6GK36` trong
   Xcode → Settings → Accounts.
5. Sau khi upload thành công, quay lại App Store Connect — build sẽ xuất
   hiện trong danh sách sau khi Apple xử lý xong (mục 8 ở checklist trên).

Nếu muốn export ra file `.ipa` thay vì upload thẳng, chọn **Distribute
App → App Store Connect → Export** thay vì **Upload** ở bước 3.

---

**Claude sẽ KHÔNG tự động thực hiện bất kỳ bước nào ở trên** (đăng nhập
tài khoản, submit review, publish site công khai) trừ khi bạn yêu cầu cụ
thể ở phiên làm việc riêng.
