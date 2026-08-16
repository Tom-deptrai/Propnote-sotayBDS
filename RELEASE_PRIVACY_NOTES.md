# PropNote — Privacy Fact Inventory

Nguồn sự thật để điền App Store "App Privacy" và Google Play "Data Safety".
Mỗi mục: mục đích, lưu ở đâu, có gửi ra ngoài không, và có backend PropNote
hay không (không có — app hoàn toàn local-first).

| Dữ liệu | Mục đích | Lưu ở đâu | Gửi ra ngoài? | Backend PropNote? |
|---|---|---|---|---|
| Thông tin BĐS (tên, địa chỉ, giá, ghi chú, trạng thái, loại, tag) | Chức năng cốt lõi của app | SQLite local (`lib/data/database`) | Không | Không |
| Hình ảnh BĐS | Ghi chú/nhận diện BĐS | Bộ nhớ thiết bị (thư mục app), tham chiếu qua `PropertyPhoto` | Không | Không |
| Tài liệu đính kèm | Lưu giấy tờ liên quan BĐS | Bộ nhớ thiết bị, tham chiếu qua `PropertyDocument` | Không | Không |
| Vị trí (GPS toạ độ) | Đặt ghim BĐS trên bản đồ, hiển thị BĐS gần vị trí hiện tại | SQLite (trường `latitude`/`longitude` của Property) | Toạ độ được gửi tới OpenFreeMap (bên thứ ba) chỉ để tải ảnh nền bản đồ khu vực tương ứng — không gắn với danh tính người dùng, không phải gửi dữ liệu BĐS | Không |
| Microphone / giọng nói | Nhập liệu bằng giọng nói (tên, ghi chú) | Xử lý qua speech-to-text của hệ điều hành (iOS/Android), PropNote chỉ nhận văn bản kết quả | Xử lý nhận dạng có thể diễn ra trên máy hoặc qua dịch vụ giọng nói của Apple/Google tuỳ hệ điều hành — PropNote không tự gửi audio đi đâu khác | Không |
| Danh bạ / liên hệ BĐS (tên, SĐT nhập tay) | Ghi chú người liên hệ cho từng BĐS | SQLite local, do người dùng tự nhập (không đọc danh bạ máy) | Không | Không |
| Bản đồ nền (map tiles) | Hiển thị bản đồ | N/A — tải trực tiếp qua Internet | Có — thiết bị tải ảnh bản đồ từ OpenFreeMap (`tiles.openfreemap.org`) mỗi khi mở màn hình Bản đồ | Không (bên thứ ba, không phải server PropNote) |
| Chỉ đường / mở bản đồ ngoài | Điều hướng tới BĐS | N/A | Có thể mở app Google Maps/bản đồ khác đã cài trên máy qua deep link — người dùng chủ động bấm | Không |
| Bản sao lưu (.zip) | Sao lưu/khôi phục dữ liệu thủ công | Do người dùng tạo và tự chọn nơi lưu/chia sẻ (Files, email, AirDrop, ...) qua share sheet hệ điều hành | Chỉ khi người dùng chủ động chia sẻ file đó đi | Không — PropNote không tự upload bản sao lưu lên đâu cả |
| Giao dịch mua PropNote Pro | Xác định quyền lợi Free/Pro | Trạng thái entitlement (chuỗi "pro"/"free") cache trong SQLite local qua `readSetting`/`writeSetting`; **giao dịch/thanh toán thật do Apple App Store / Google Play xử lý và lưu trữ, PropNote không thấy và không lưu số thẻ hay thông tin thanh toán** | Có — xử lý qua StoreKit (Apple)/Play Billing (Google), theo chính sách riêng của các nền tảng đó | Không |

## Ghi chú khi điền form store

### App Store — App Privacy

- "Data Used to Track You": **Không** (PropNote không tracking/quảng cáo).
- "Data Linked to You": có thể khai **Purchases** (App Store xử lý, không
  phải PropNote thu thập) nếu Apple yêu cầu khai mục này cho giao dịch IAP —
  tham khảo hướng dẫn App Store hiện hành khi điền, vì Apple tự động biết
  giao dịch IAP nó xử lý.
- "Data Not Linked to You": **Location** (dùng để đặt ghim/hiển thị BĐS gần
  bạn — không liên kết với danh tính, không rời khỏi mục đích trong app).
- Không khai bất kỳ mục nào liên quan "Contact Info", "Health", "Financial
  Info" do PropNote thu thập trực tiếp — các trường "liên hệ BĐS" là dữ liệu
  người dùng tự nhập cho MỤC ĐÍCH RIÊNG của họ (ghi chú cá nhân), không phải
  PropNote thu thập thông tin liên hệ của chính người dùng app.

### Google Play — Data Safety

- "Does your app collect or share any of the required user data types?":
  **Có** — khai **Location** (approximate + precise, dùng cho App
  functionality, không chia sẻ với bên thứ ba ngoài việc tải map tile ẩn
  danh).
- **Photos and videos**, **Files and docs**: xử lý local trên thiết bị,
  không rời thiết bị trừ khi người dùng tự share (đánh dấu "collected: No"
  nếu Play hỏi theo nghĩa "gửi ra ngoài app/server" — chọn theo hướng dẫn
  hiện hành của Play Console cho dữ liệu chỉ lưu on-device).
- **Financial info**: KHÔNG khai PropNote thu thập — giao dịch subscription
  do Google Play Billing xử lý trực tiếp, không qua PropNote.
- Không có mục nào cần khai "shared with third parties for advertising".

### Cả hai store

- Không có tài khoản người dùng (no sign-in) — không có "Account creation"
  hay "User ID" nào để khai.
- Không có analytics/crash-reporting SDK bên thứ ba nào được tích hợp tại
  thời điểm 1.0 (audit lại `pubspec.yaml` nếu sau này thêm Firebase/Sentry/...
  — khi đó cần cập nhật lại bảng này và cả 2 form trước khi release tiếp).
