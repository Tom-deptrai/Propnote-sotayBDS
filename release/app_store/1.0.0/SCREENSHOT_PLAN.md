# Screenshot Plan — PropNote 1.0.0

Đề xuất 7 màn hình, thứ tự ưu tiên hiển thị trên App Store (màn 1-3 là
quan trọng nhất, người dùng thường chỉ lướt qua vài ảnh đầu).

Đây là plan tài liệu — **chưa tự động chụp** (xem lý do ở cuối file).

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
