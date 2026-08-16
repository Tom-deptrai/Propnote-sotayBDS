# PropNote — Sổ tay bất động sản cá nhân

> "Sổ tay bất động sản cá nhân có bản đồ và thư viện ảnh."

PropNote (Flutter) là ứng dụng dành cho môi giới BĐS cá nhân và người thường
xuyên đi khảo sát nhà đất, giúp ghi nhớ vị trí, hình ảnh và thông tin của
từng bất động sản. Local-first, không tài khoản, không phải CRM.

## Tính năng

- **Lưu trữ local-first**: toàn bộ dữ liệu nằm trong SQLite + bộ nhớ thiết
  bị, không cần tài khoản, không đồng bộ máy chủ.
- **Bản đồ**: MapLibre GL + bản đồ local (PMTiles đóng gói sẵn trong app) cho
  TP.HCM + Hà Nội, hoàn toàn offline — không phụ thuộc dịch vụ tile online
  nào. Marker theo trạng thái BĐS, label giá tuỳ chọn, vị trí GPS hiện tại
  (bật/tắt), chọn vị trí bằng cách kéo bản đồ. Ngoài 2 khu vực trên, bản đồ
  hiện nền trống + thông báo chưa hỗ trợ — toạ độ BĐS vẫn dùng bình thường ở
  bất kỳ đâu (xem `MapCoveragePolicy`).
- **Thêm/sửa BĐS**: ảnh chụp/thư viện, tài liệu đính kèm, nhập liệu bằng
  giọng nói (speech-to-text), quản lý Loại BĐS/Tags/Khu vực tuỳ biến.
- **Danh sách & tìm kiếm**: lọc theo trạng thái, sắp xếp, tìm kiếm theo
  tên/địa chỉ/khu vực/ghi chú/tag.
- **Sao lưu & khôi phục**: xuất một tệp `.zip` chứa toàn bộ dữ liệu + media
  để tự lưu trữ hoặc chuyển thiết bị; khôi phục lại từ tệp đó.
- **Thùng rác**: xoá mềm trước, khôi phục hoặc xoá vĩnh viễn sau.
- **Free / Pro**: gói Free tạo tối đa 10 bất động sản (miễn phí, không giới
  hạn thời gian); gói PropNote Pro (đăng ký theo năm, tự động gia hạn qua
  App Store/Google Play) mở khoá không giới hạn số lượng.

## Thiết kế

- Phong cách: Premium Minimal / Professional Property Tool
- Màu thương hiệu: Navy `#1E3A5F`
- Trạng thái BĐS: Đỏ = Đang bán, Xanh = Chưa khảo sát, Xám = Đã bán
- Bottom navigation 3 tab: Bản đồ · Danh sách · Cài đặt

## Chạy thử

```
flutter pub get
flutter run -d <device_id>
```

## Công nghệ

Flutter (Dart), `provider`, `sqflite`, `maplibre_gl` (PMTiles local),
`geolocator`, `image_picker`, `file_picker`, `speech_to_text`, `share_plus`,
`archive` (sao lưu/khôi phục), `in_app_purchase` (PropNote Pro subscription).

Dữ liệu bản đồ: OpenStreetMap/Geofabrik (ODbL) → Planetiler + schema
OpenMapTiles → PMTiles, fonts từ `openmaptiles/fonts` (SIL OFL 1.1). Xem
`RELEASE_PRIVACY_NOTES.md` để biết chi tiết nguồn/license.

## Nền tảng

iOS và Android. Bundle/Application ID: `com.propnote.propnote`.
