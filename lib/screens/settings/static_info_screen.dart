import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class StaticInfoScreen extends StatelessWidget {
  final String title;
  final String body;

  const StaticInfoScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          body,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

const String kPrivacyPolicyText = '''
PropNote là ứng dụng local-first: toàn bộ dữ liệu bất động sản (thông tin, hình ảnh, tài liệu, ghi chú) được lưu trực tiếp trên thiết bị của bạn — trong cơ sở dữ liệu SQLite và bộ nhớ ứng dụng, không đồng bộ lên máy chủ của PropNote và không yêu cầu tạo tài khoản.

Dữ liệu và quyền truy cập
- Vị trí (GPS): dùng để đặt ghim và xác định toạ độ cho từng bất động sản khi bạn chọn "Vị trí hiện tại". Chỉ dùng khi bạn đang mở ứng dụng, không thu thập vị trí nền.
- Camera / thư viện ảnh: dùng để chụp hoặc chọn ảnh, tài liệu đính kèm cho bất động sản.
- Microphone / nhận dạng giọng nói: dùng để chuyển giọng nói thành văn bản khi bạn nhập tên hoặc ghi chú bằng giọng nói. Việc nhận dạng giọng nói do hệ điều hành (iOS/Android) xử lý.
- Bản đồ: PropNote hiển thị bản đồ nền bằng dịch vụ bên ngoài (OpenFreeMap) — thiết bị của bạn tải hình ảnh bản đồ qua Internet khi bạn mở màn hình Bản đồ. Khi bạn dùng tính năng chỉ đường, PropNote có thể mở ứng dụng bản đồ khác (vd. Google Maps) trên thiết bị.

Sao lưu và khôi phục
Bạn có thể chủ động tạo bản sao lưu (một tệp .zip chứa dữ liệu và media) và chia sẻ nó tới nơi bạn chọn (Files, email, AirDrop, ...), hoặc khôi phục từ một tệp sao lưu đã có. Đây là thao tác thủ công do bạn thực hiện — PropNote không tự động tải bản sao lưu lên bất kỳ máy chủ nào.

Chúng tôi không thu thập, chia sẻ hay bán dữ liệu bất động sản, hình ảnh, hay vị trí của bạn cho bên thứ ba.

Đăng ký PropNote Pro
Nếu bạn nâng cấp lên PropNote Pro, giao dịch mua được xử lý hoàn toàn bởi Apple App Store hoặc Google Play — PropNote không tự lưu số thẻ hay thông tin thanh toán của bạn. PropNote chỉ lưu cục bộ trên thiết bị trạng thái gói đăng ký (Free/Pro) để xác định quyền sử dụng; việc quản lý, huỷ hoặc thay đổi phương thức thanh toán được thực hiện trực tiếp trong Cài đặt tài khoản App Store/Google Play của bạn.

Vì dữ liệu nằm hoàn toàn trên thiết bị (trừ giao dịch mua qua App Store/Google Play nêu trên), bạn là người duy nhất chịu trách nhiệm sao lưu dữ liệu của mình.
''';

const String kAboutText = '''
PropNote — Sổ tay bất động sản cá nhân

"Sổ tay bất động sản cá nhân có bản đồ và thư viện ảnh."

PropNote được thiết kế cho môi giới bất động sản cá nhân và những người thường xuyên đi khảo sát nhà đất — giúp ghi nhớ vị trí, hình ảnh và thông tin của từng căn nhà một cách nhanh chóng, không cần thao tác phức tạp.

Ứng dụng tập trung vào sự đơn giản và tốc độ, không phải một CRM và không quản lý khách hàng. Toàn bộ dữ liệu được lưu ngay trên thiết bị của bạn.

Nền tảng: Flutter
''';

const String kTermsOfUseText = '''
Điều khoản sử dụng PropNote

PropNote là ứng dụng ghi chú bất động sản cá nhân, dữ liệu lưu trên thiết bị của bạn.

Gói Free
Sử dụng miễn phí, không giới hạn thời gian, tối đa 10 bất động sản (bao gồm cả bất động sản đang trong Thùng rác — dữ liệu trong Thùng rác vẫn có thể khôi phục nên vẫn tính vào giới hạn; chỉ xoá vĩnh viễn mới giải phóng chỗ trống).

Gói PropNote Pro
- Gói đăng ký theo năm, tự động gia hạn (auto-renewable subscription).
- Không giới hạn số lượng bất động sản trong suốt thời gian gói còn hiệu lực.
- Thanh toán được xử lý qua Apple App Store hoặc Google Play theo phương thức thanh toán bạn đã thiết lập với tài khoản đó.
- Gói sẽ tự động gia hạn trừ khi bạn tắt tự động gia hạn ít nhất 24 giờ trước khi kết thúc chu kỳ hiện tại. Bạn có thể quản lý hoặc huỷ đăng ký bất kỳ lúc nào trong phần Cài đặt tài khoản App Store (iOS) hoặc Google Play (Android).
- Nếu gói Pro hết hạn hoặc bị huỷ, tài khoản của bạn trở lại gói Free: toàn bộ dữ liệu đã có vẫn được giữ nguyên, xem/sửa/xoá/sao lưu bình thường — chỉ việc tạo bất động sản mới sẽ bị giới hạn lại nếu bạn đang có từ 10 bất động sản trở lên.
- Có thể khôi phục giao dịch mua đã thực hiện trước đó (khi đổi thiết bị hoặc cài lại ứng dụng) qua mục "Khôi phục giao dịch mua".

Bằng việc mua PropNote Pro, bạn đồng ý với điều khoản dịch vụ tiêu chuẩn của Apple App Store hoặc Google Play áp dụng cho giao dịch mua trong ứng dụng.
''';
