# PropNote — Privacy Fact Inventory

Nguồn sự thật để điền App Store "App Privacy" và Google Play "Data Safety".
PropNote **hoàn toàn local-first — không có backend riêng**. Bảng dưới phân
loại rõ theo 3 nhóm, vì "xử lý trên thiết bị, không rời thiết bị" và "được
gửi ra ngoài" là 2 khái niệm khác nhau và cả 2 store đều phân biệt rõ điều
này trong form khai báo của họ:

- **(A) Chỉ xử lý/lưu trên thiết bị** — không có request mạng nào mang dữ
  liệu này ra khỏi máy trong luồng bình thường của app.
- **(B) Có thể được nền tảng/vendor xử lý** — không phải PropNote tự gửi,
  mà do chức năng hệ điều hành (nhận dạng giọng nói) hoặc do Apple/Google
  tự vận hành (IAP) xử lý thay, PropNote không thấy nội dung/không lưu.
- **(C) Người dùng chủ động chia sẻ ra ngoài** — chỉ rời thiết bị khi chính
  người dùng bấm hành động chia sẻ/mở app khác, không tự động.

## (A) Chỉ xử lý/lưu trên thiết bị

| Dữ liệu | Mục đích | Lưu ở đâu |
|---|---|---|
| Thông tin BĐS (tên, địa chỉ, giá, ghi chú, trạng thái, loại, tag) | Chức năng cốt lõi của app | SQLite local (`lib/data/database`) |
| Hình ảnh BĐS | Ghi chú/nhận diện BĐS | Bộ nhớ thiết bị (thư mục app), tham chiếu qua `PropertyPhoto` |
| Tài liệu đính kèm | Lưu giấy tờ liên quan BĐS | Bộ nhớ thiết bị, tham chiếu qua `PropertyDocument` |
| Vị trí (GPS toạ độ) | Đặt ghim BĐS trên bản đồ, hiển thị BĐS gần vị trí hiện tại | SQLite (trường `latitude`/`longitude` của Property) — GPS đọc qua `geolocator`, KHÔNG có request mạng nào gửi toạ độ này ra ngoài; bản đồ nền là PMTiles đóng gói sẵn trong app, render hoàn toàn local |
| Danh bạ / liên hệ BĐS (tên, SĐT nhập tay) | Ghi chú người liên hệ cho từng BĐS | SQLite local, do người dùng tự nhập (không đọc danh bạ máy) |
| Bản đồ nền (PMTiles + fonts) | Hiển thị bản đồ cho TP.HCM + Hà Nội | Đóng gói sẵn trong app (`assets/map/*.pmtiles`), copy ra thư mục local khi cần — không có request mạng nào cho style/tile/font/sprite ở bất kỳ bước nào |
| Trạng thái entitlement Free/Pro (cache) | Hiển thị UI Free/Pro nhanh lúc mở app | Chuỗi "pro"/"free" cache trong SQLite local qua `readSetting`/`writeSetting` — bản thân cache này không rời thiết bị (xem mục IAP ở nhóm B để phân biệt với giao dịch mua thật) |

## (B) Có thể được nền tảng/vendor xử lý (không phải PropNote tự gửi)

| Dữ liệu | Mục đích | Ai xử lý |
|---|---|---|
| Microphone / giọng nói | Nhập liệu bằng giọng nói (tên, ghi chú) | Nhận dạng giọng nói của hệ điều hành (`speech_to_text`) — có thể xử lý on-device hoặc qua dịch vụ giọng nói của Apple/Google tuỳ phiên bản OS/thiết bị, PropNote chỉ nhận văn bản kết quả, không tự gửi audio đi đâu khác và không lưu file âm thanh |
| Giao dịch mua PropNote Pro | Xác định quyền lợi Free/Pro | Do Apple App Store (StoreKit)/Google Play (Play Billing) xử lý và lưu trữ trực tiếp theo chính sách riêng của từng nền tảng — PropNote không thấy và không lưu số thẻ/thông tin thanh toán, chỉ nhận lại kết quả giao dịch (thành công/thất bại/còn hiệu lực hay không) |

## (C) Người dùng chủ động chia sẻ ra ngoài

| Dữ liệu | Mục đích | Khi nào rời thiết bị |
|---|---|---|
| Bản sao lưu (.zip) | Sao lưu/khôi phục dữ liệu thủ công | Chỉ khi người dùng tự tạo backup VÀ tự chọn nơi lưu/chia sẻ (Files, email, AirDrop, ...) qua share sheet hệ điều hành — PropNote không tự upload bản sao lưu lên đâu cả |
| Chỉ đường / mở bản đồ ngoài | Điều hướng tới BĐS | Chỉ khi người dùng chủ động bấm "Chỉ đường bằng Google Maps" — mở app Google Maps/bản đồ khác đã cài trên máy qua deep link (cần Internet cho bước này, khác với bản đồ nền trong app luôn offline) |

## Ghi chú khi điền form store

**Quan trọng:** bảng trên là sự thật hiện tại của implementation, nhưng
cách 2 form của Apple/Google diễn giải "collected" cho dữ liệu chỉ xử lý
on-device có thể thay đổi theo thời gian và theo đúng câu hỏi cụ thể trong
Console lúc submit — **luôn đối chiếu lại với form App Store Connect/Play
Console hiện hành tại thời điểm submit**, không suy diễn máy móc từ tài
liệu này.

### App Store — App Privacy

- "Data Used to Track You": **Không** (PropNote không tracking/quảng cáo).
- **Location**: dữ liệu ở nhóm (A) — xử lý/lưu hoàn toàn on-device, không
  có request mạng nào gửi toạ độ ra khỏi máy (kể cả để hiển thị bản đồ, vì
  bản đồ nền là PMTiles local). Theo hướng dẫn App Store Connect, dữ liệu
  không rời thiết bị thường KHÔNG cần khai là "collected" — nhưng vì Apple
  có thể diễn giải "sử dụng GPS API" khác với "truyền dữ liệu ra ngoài",
  cần đối chiếu đúng câu hỏi cụ thể trong Console lúc submit thay vì tự
  khẳng định trước ở đây.
- **Purchases**: giao dịch IAP do Apple/StoreKit tự xử lý trực tiếp (nhóm
  B) — Apple thường tự biết giao dịch nó xử lý, tham khảo hướng dẫn App
  Store Connect hiện hành cho mục này khi điền.
- Không khai bất kỳ mục nào liên quan "Contact Info", "Health", "Financial
  Info" do PropNote thu thập trực tiếp — các trường "liên hệ BĐS" là dữ
  liệu người dùng tự nhập cho MỤC ĐÍCH RIÊNG của họ (ghi chú cá nhân),
  không phải PropNote thu thập thông tin liên hệ của chính người dùng app.

### Google Play — Data Safety

- Play Console phân biệt rõ "collected" (rời thiết bị) và dữ liệu chỉ xử
  lý on-device — theo tài liệu Play Console hiện hành, dữ liệu KHÔNG được
  truyền ra khỏi thiết bị (kể cả khi app có dùng API tương ứng, vd. GPS)
  thường không tính là "collected/shared" theo nghĩa Data Safety yêu cầu
  khai. **Location** trong PropNote thuộc nhóm (A) này — trước khi khai
  "Collects: Yes/No", đối chiếu lại đúng câu hỏi hiện hành trong Play
  Console (wording có thể đổi theo thời gian) thay vì khẳng định cứng ở
  đây.
- **Photos and videos**, **Files and docs**: xử lý local trên thiết bị,
  không rời thiết bị trừ khi người dùng tự share — chọn theo hướng dẫn
  hiện hành của Play Console cho dữ liệu chỉ lưu on-device.
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
  contributors` — khai báo TƯỜNG MINH trên vector source trong style JSON
  (`BasemapProviders.active.attribution`, gắn vào `sources.openmaptiles
  .attribution` trong `lib/data/services/map/basemap_provider.dart`) VÀ
  hiển thị qua nút info/attribution mặc định của MapLibre trên UI bản đồ —
  đã xác nhận hiện đúng cho cả 2 vùng (TP.HCM/Hà Nội) và giữ nguyên sau khi
  chuyển vùng, không cần xử lý thêm.
- Không crawl/scrape tile endpoint của bất kỳ provider nào — toàn bộ dữ liệu
  tự build từ OSM thô, không phụ thuộc ToS của dịch vụ tile bên thứ ba nào.

### Cả hai store

- Không có tài khoản người dùng (no sign-in) — không có "Account creation"
  hay "User ID" nào để khai.
- Không có analytics/crash-reporting SDK bên thứ ba nào được tích hợp tại
  thời điểm 1.0 (audit lại `pubspec.yaml` nếu sau này thêm Firebase/Sentry/...
  — khi đó cần cập nhật lại bảng này và cả 2 form trước khi release tiếp).
