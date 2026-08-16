# PropNote — Privacy Fact Inventory

Nguồn sự thật để điền App Store "App Privacy" và Google Play "Data Safety".
Mỗi mục: mục đích, lưu ở đâu, có gửi ra ngoài không, và có backend PropNote
hay không (không có — app hoàn toàn local-first).

| Dữ liệu | Mục đích | Lưu ở đâu | Gửi ra ngoài? | Backend PropNote? |
|---|---|---|---|---|
| Thông tin BĐS (tên, địa chỉ, giá, ghi chú, trạng thái, loại, tag) | Chức năng cốt lõi của app | SQLite local (`lib/data/database`) | Không | Không |
| Hình ảnh BĐS | Ghi chú/nhận diện BĐS | Bộ nhớ thiết bị (thư mục app), tham chiếu qua `PropertyPhoto` | Không | Không |
| Tài liệu đính kèm | Lưu giấy tờ liên quan BĐS | Bộ nhớ thiết bị, tham chiếu qua `PropertyDocument` | Không | Không |
| Vị trí (GPS toạ độ) | Đặt ghim BĐS trên bản đồ, hiển thị BĐS gần vị trí hiện tại | SQLite (trường `latitude`/`longitude` của Property) | Không — bản đồ nền là dữ liệu đóng gói cục bộ trong app (PMTiles), toạ độ không được gửi ra ngoài để hiển thị bản đồ | Không |
| Microphone / giọng nói | Nhập liệu bằng giọng nói (tên, ghi chú) | Xử lý qua speech-to-text của hệ điều hành (iOS/Android), PropNote chỉ nhận văn bản kết quả | Xử lý nhận dạng có thể diễn ra trên máy hoặc qua dịch vụ giọng nói của Apple/Google tuỳ hệ điều hành — PropNote không tự gửi audio đi đâu khác | Không |
| Danh bạ / liên hệ BĐS (tên, SĐT nhập tay) | Ghi chú người liên hệ cho từng BĐS | SQLite local, do người dùng tự nhập (không đọc danh bạ máy) | Không | Không |
| Bản đồ nền (PMTiles) | Hiển thị bản đồ cho TP.HCM + Hà Nội | Đóng gói sẵn trong app (`assets/map/*.pmtiles`), copy ra thư mục local khi cần | Không — hoàn toàn offline, không có request mạng nào cho style/tile/font/sprite | Không |
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
  bạn — không liên kết với danh tính, không rời khỏi mục đích trong app,
  không gửi ra ngoài để hiển thị bản đồ vì bản đồ nền hoàn toàn local).
- Không khai bất kỳ mục nào liên quan "Contact Info", "Health", "Financial
  Info" do PropNote thu thập trực tiếp — các trường "liên hệ BĐS" là dữ liệu
  người dùng tự nhập cho MỤC ĐÍCH RIÊNG của họ (ghi chú cá nhân), không phải
  PropNote thu thập thông tin liên hệ của chính người dùng app.

### Google Play — Data Safety

- "Does your app collect or share any of the required user data types?":
  **Có** — khai **Location** (approximate + precise, dùng cho App
  functionality; KHÔNG chia sẻ với bên thứ ba nào — bản đồ nền hoàn toàn
  local, không có request mạng nào mang theo toạ độ người dùng).
- **Photos and videos**, **Files and docs**: xử lý local trên thiết bị,
  không rời thiết bị trừ khi người dùng tự share (đánh dấu "collected: No"
  nếu Play hỏi theo nghĩa "gửi ra ngoài app/server" — chọn theo hướng dẫn
  hiện hành của Play Console cho dữ liệu chỉ lưu on-device).
- **Financial info**: KHÔNG khai PropNote thu thập — giao dịch subscription
  do Google Play Billing xử lý trực tiếp, không qua PropNote.
- Không có mục nào cần khai "shared with third parties for advertising".

### Nguồn dữ liệu bản đồ local (PMTiles)

- Dữ liệu địa lý gốc: OpenStreetMap, qua Geofabrik (giấy phép ODbL).
- Pipeline dựng tile: Planetiler (Apache 2.0), dùng schema/style chuẩn
  OpenMapTiles.
- Fonts glyph: `openmaptiles/fonts` (SIL Open Font License 1.1), chỉ dùng
  Noto Sans Regular (3 range Latin cần cho tiếng Việt).
- Attribution bắt buộc theo license: `© OpenMapTiles © OpenStreetMap
  contributors` — hiện lưu tại [`BasemapProviders.active.attribution`]
  (`lib/data/services/map/basemap_provider.dart`); **CẦN xác nhận lại UI có
  hiển thị dòng attribution này cho người dùng ở nơi phù hợp trước khi phát
  hành** (bản OpenFreeMap trước đó cũng chưa có UI hiển thị attribution —
  đây là khoảng trống tồn tại từ trước, không phải mới phát sinh, nhưng nên
  xử lý trước khi release chính thức để tuân thủ đầy đủ ODbL "Produced Work"
  doctrine).
- Không crawl/scrape tile endpoint của bất kỳ provider nào — toàn bộ dữ liệu
  tự build từ OSM thô, không phụ thuộc ToS của dịch vụ tile bên thứ ba nào.

### Cả hai store

- Không có tài khoản người dùng (no sign-in) — không có "Account creation"
  hay "User ID" nào để khai.
- Không có analytics/crash-reporting SDK bên thứ ba nào được tích hợp tại
  thời điểm 1.0 (audit lại `pubspec.yaml` nếu sau này thêm Firebase/Sentry/...
  — khi đó cần cập nhật lại bảng này và cả 2 form trước khi release tiếp).
