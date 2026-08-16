# Screenshot Plan — PropNote 1.0.0

Đề xuất 7 màn hình, thứ tự ưu tiên hiển thị trên App Store (màn 1-3 là
quan trọng nhất, người dùng thường chỉ lướt qua vài ảnh đầu).

## Kết quả đã chụp tự động (Phase 1)

Đã boot **iPhone 17 Pro Max** (iOS 26.5, kích thước 6.9" — đúng size lớn
nhất App Store Connect yêu cầu hiện nay), build app ở chế độ Debug cho
Simulator (Release không hỗ trợ Simulator), cài và chạy thành công.

3/7 màn hình đã chụp sạch, an toàn, lưu tại
`release/app_store/1.0.0/screenshots_raw/`:

| File | Màn hình | Ghi chú |
|---|---|---|
| `01_map_hcm_empty.png` | Bản đồ TP.HCM | Render đẹp, đầy đủ tên đường/sông — không có marker vì chưa có dữ liệu mẫu |
| `02_settings.png` | Cài đặt | Cho thấy "Dung lượng đang sử dụng: 148.0 KB" (fix hoạt động thật) và "Phiên bản 1.0.0 (2)" |
| `03_map_hanoi_empty.png` | Bản đồ Hà Nội | Render đẹp sau khi chuyển vùng, không còn banner "chưa hỗ trợ" |

**4/7 màn hình còn lại KHÔNG tự động chụp được trong lượt này** (Danh sách
có dữ liệu, Chi tiết BĐS, Bản đồ có marker+giá, Add/Edit đã điền, Location
Picker, Search/filter có kết quả) — lý do kỹ thuật cụ thể: công cụ điều
khiển Simulator hiện tại chỉ gửi được ký tự ASCII qua bàn phím ảo (đã xác
nhận: gõ "Nhà phố Nguyễn Huệ" bị rớt 4 ký tự có dấu), không có thao tác
paste từ clipboard. Nhập tên bất động sản tiếng Việt có dấu — vốn bắt buộc
để ảnh chụp trông đúng và chuyên nghiệp — không thể thực hiện đáng tin cậy
qua công cụ tự động này. Đây không phải giới hạn kỹ thuật của app, chỉ là
giới hạn của công cụ điều khiển Simulator trong phiên làm việc này.

**Cách hoàn tất phần còn lại (nhanh, ~10-15 phút):** mở Simulator
(`iPhone 17 Pro Max` đã cài sẵn app, hoặc `flutter run` lại), tự gõ tay
2-3 BĐS mẫu theo đúng dữ liệu đề xuất ở bảng dưới (gõ tay bằng bàn phím
Mac có dấu, không qua công cụ tự động), rồi dùng `Cmd+S` hoặc
Device → Trigger Screenshot trong Simulator, hoặc yêu cầu Claude chụp
tiếp ở phiên làm việc riêng sau khi dữ liệu mẫu đã có sẵn trên máy.

Đây là plan tài liệu cho 4 màn hình còn lại — xem chi tiết dữ liệu mẫu bên
dưới.

| # | Màn hình | Trạng thái cần chuẩn bị | Caption tiếng Việt đề xuất |
|---|---|---|---|
| 1 | **Bản đồ + price markers** | Map Screen, vùng TP.HCM hoặc Hà Nội, có vài BĐS mẫu với marker + label giá hiện, showPrice bật | "Xem toàn bộ bất động sản trên bản đồ, kèm giá" |
| 2 | **Danh sách BĐS** | List Screen, có 5-8 BĐS mẫu đa dạng trạng thái (Đang bán/Chưa khảo sát/Đã bán) | "Danh sách rõ ràng, lọc theo trạng thái" |
| 3 | **Chi tiết BĐS** | Property Detail của 1 BĐS mẫu có đủ ảnh, giá, diện tích, vị trí | "Lưu đầy đủ thông tin cho từng bất động sản" |
| 4 | **Thêm/chỉnh sửa BĐS** | Add Property Screen, form đã điền 1 phần (tên, giá, loại BĐS chọn sẵn) | "Thêm bất động sản nhanh chóng khi đang khảo sát" |
| 5 | **Location Picker** | Location Picker mở tại 1 vị trí cụ thể, crosshair giữa màn hình, region selector TP.HCM/Hà Nội hiện | "Chọn chính xác vị trí trên bản đồ" |
| 6 | **Search/filter** | List hoặc Map Screen với Advanced Filter sheet đang mở, vài filter đã chọn | "Tìm kiếm và lọc theo giá, loại, khu vực" |
| 7 | **Settings/Pro** | Settings Screen, hiện card PropNote Pro + mục Sao lưu/Thùng rác | "Sao lưu dữ liệu, nâng cấp Pro khi cần" |

## Chuẩn bị dữ liệu mẫu cho screenshot

- Dùng **Simulator** với dữ liệu TEST/FIXTURE (property mock có sẵn trong
  app hoặc tự tạo vài BĐS mẫu bằng tên/địa chỉ giả định rõ ràng — vd. "Nhà
  phố Nguyễn Huệ", "Căn hộ Landmark 81") — **không dùng dữ liệu thật của
  bạn** để tránh lộ thông tin cá nhân/khách hàng thật lên App Store công
  khai.
- Đặt marker/property mẫu trong đúng vùng phủ bản đồ (TP.HCM hoặc Hà Nội)
  để ảnh không rơi vào trạng thái nền xám "chưa hỗ trợ khu vực".
- **Không chụp** lúc banner "Bản đồ chưa hỗ trợ khu vực này." đang hiện,
  và không chụp bất kỳ debug banner/lỗi nào.
- Ảnh phải phản ánh đúng chức năng thật — không chỉnh sửa/thêm nội dung
  không có trong app.

## Kích thước cần cho App Store Connect

App Store Connect yêu cầu screenshot theo TỪNG kích thước thiết bị cụ thể
(iPhone 6.9", 6.5", iPad nếu hỗ trợ...) — kích thước chính xác thay đổi
theo thời điểm submit, `VERIFY IN CURRENT APP STORE CONNECT FORM` trước
khi upload thay vì dùng số cố định ở đây.

## Vì sao chưa tự động chụp trong lượt này

Việc chụp screenshot sạch đúng plan (dữ liệu mẫu, đúng vùng bản đồ, đúng
trạng thái UI cho từng màn ở trên) cần tương tác nhiều bước qua Simulator
+ tạo dữ liệu fixture riêng biệt với database thật của bạn trên máy — để
tránh rủi ro động vào dữ liệu development hiện có, bước này **không được tự
động thực hiện trong lượt làm việc hiện tại** (ngoài phạm vi yêu cầu gốc:
merge + release prep). Đây không phải blocker kỹ thuật — chỉ cần 1 phiên
làm việc riêng (hoặc bạn tự chụp thủ công theo plan trên) khi sẵn sàng.

Thư mục `release/app_store/1.0.0/screenshots_raw/` chưa được tạo — sẽ tạo
khi có ảnh thật để lưu vào.
