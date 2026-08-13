# PropNote — Sổ tay bất động sản cá nhân

> "Sổ tay bất động sản cá nhân có bản đồ và thư viện ảnh."

UI prototype (Flutter) cho PropNote — ứng dụng dành cho môi giới BĐS cá nhân
và người thường xuyên đi khảo sát nhà đất, giúp ghi nhớ vị trí, hình ảnh và
thông tin của từng bất động sản. Local-first, không tài khoản, không phải CRM.

Đây là **giai đoạn UI prototype**: giao diện được đầu tư đầy đủ và có thể
bấm qua lại giữa các màn hình, nhưng SQLite, Google Maps thật, GPS, camera,
backup, subscription/thanh toán, cloud và authentication đều **chưa** được
triển khai — toàn bộ dùng dữ liệu mock trong bộ nhớ (session-only).

## Thiết kế

- Phong cách: Premium Minimal / Professional Property Tool
- Màu thương hiệu: Navy `#1E3A5F`
- Trạng thái BĐS: Đỏ = Đang bán, Xanh = Chưa khảo sát, Xám = Đã bán
- Bottom navigation 3 tab: Bản đồ · Danh sách · Cài đặt

## Màn hình đã có

- **Bản đồ** — bản đồ cách điệu vẽ bằng `CustomPainter` (sông, công viên,
  đường xá, nhãn khu vực), pan/zoom, marker màu theo trạng thái, cluster,
  thanh tìm kiếm, filter chip, bottom sheet xem nhanh, nút định vị.
- **Danh sách** — tìm kiếm toàn cục, tab khu vực, card BĐS, bộ lọc
  (trạng thái/giá/diện tích).
- **Thêm / Chỉnh sửa BĐS** — form nhanh: ảnh, trạng thái, khu vực, chọn vị
  trí trên bản đồ, thông tin chính, tags, ghi chú, ngày khảo sát.
- **Chi tiết BĐS** — gallery ảnh, giá nổi bật, thông tin, tags, ghi chú,
  preview vị trí, đổi trạng thái / chuyển khu vực / xoá.
- **Cài đặt** — dữ liệu (sao lưu/khôi phục/dung lượng/thùng rác), quản lý
  khu vực, PropNote Pro, thông tin ứng dụng.
- **Quản lý khu vực** — thêm/đổi tên/xoá/sắp xếp.
- **Thùng rác** — khôi phục / xoá vĩnh viễn.

## Chạy thử

```bash
flutter pub get
flutter run -d <device_id>   # iOS Simulator
# hoặc
flutter run -d chrome        # Flutter Web (phương án dự phòng)
```

## Công nghệ

Flutter (Dart), `provider` cho state trong phiên, `intl` để định dạng
tiền tệ/ngày tháng. Không phụ thuộc API ảnh/bản đồ online — ảnh và bản đồ
đều là placeholder vẽ bằng code để chạy offline hoàn toàn.
