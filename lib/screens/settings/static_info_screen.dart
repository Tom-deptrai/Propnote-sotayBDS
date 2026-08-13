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
          style: const TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

const String kPrivacyPolicyText = '''
PropNote là ứng dụng local-first: toàn bộ dữ liệu bất động sản, hình ảnh và ghi chú của bạn được lưu trực tiếp trên thiết bị, không đồng bộ lên máy chủ và không yêu cầu tạo tài khoản.

Chúng tôi không thu thập, chia sẻ hay bán dữ liệu cá nhân của bạn cho bên thứ ba. Vị trí và hình ảnh bạn khảo sát chỉ phục vụ mục đích cá nhân của bạn.

Vì dữ liệu nằm hoàn toàn trên thiết bị, bạn là người duy nhất chịu trách nhiệm sao lưu. PropNote sẽ cung cấp công cụ sao lưu/khôi phục thủ công trong bản phát hành đầy đủ.

Đây là bản UI prototype — các mục trên chỉ minh hoạ hành vi dự kiến, chưa xử lý dữ liệu thật.
''';

const String kAboutText = '''
PropNote — Sổ tay bất động sản cá nhân

"Sổ tay bất động sản cá nhân có bản đồ và thư viện ảnh."

PropNote được thiết kế cho môi giới bất động sản cá nhân và những người thường xuyên đi khảo sát nhà đất — giúp ghi nhớ vị trí, hình ảnh và thông tin của từng căn nhà một cách nhanh chóng, không cần thao tác phức tạp.

Ứng dụng tập trung vào sự đơn giản và tốc độ, không phải một CRM và không quản lý khách hàng.

Phiên bản: 1.0.0 (UI Prototype)
Nền tảng: Flutter
''';
