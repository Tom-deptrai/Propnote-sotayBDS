import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/settings/static_info_screen.dart';
import '../theme/app_colors.dart';
import '../utils/app_messenger.dart';
import 'subscription_service.dart';
import 'subscription_state.dart';

/// Mở paywall PropNote Pro. Trả về `true` nếu người dùng mua/khôi phục
/// thành công trong phiên này (gọi nơi cần biết để tự tiếp tục flow, vd.
/// mở lại Add Property ngay sau khi nâng cấp).
Future<bool> showPaywallScreen(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => const PaywallScreen(),
      fullscreenDialog: true,
    ),
  );
  return result ?? false;
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _restoring = false;
  SubscriptionTier _lastTier = SubscriptionTier.unknown;
  SubscriptionService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<SubscriptionService>();
    if (_service != service) {
      _service?.removeListener(_onSubscriptionChanged);
      _service = service;
      _lastTier = service.state.tier;
      service.addListener(_onSubscriptionChanged);
    }
  }

  @override
  void dispose() {
    _service?.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (!mounted) return;
    final state = _service!.state;
    if (state.tier == SubscriptionTier.pro &&
        _lastTier != SubscriptionTier.pro) {
      // Vừa chuyển sang Pro trong phiên paywall này (mua hoặc restore
      // thành công) — đóng paywall và báo cho caller để tự tiếp tục flow.
      _lastTier = state.tier;
      Navigator.of(context).pop(true);
      return;
    }
    if (state.tier == SubscriptionTier.error && state.errorMessage != null) {
      showAppSnackBar(state.errorMessage!);
    }
    _lastTier = state.tier;
  }

  Future<void> _restore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    try {
      await context.read<SubscriptionService>().restore();
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SubscriptionService>();
    final state = service.state;

    final isPending = state.tier == SubscriptionTier.pending;
    final priceLabel = state.localizedPrice;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.gold,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'PropNote Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng ký theo năm để sử dụng PropNote Pro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              const _BenefitRow(text: 'Không giới hạn số lượng bất động sản'),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (priceLabel == null && service.productUnavailable)
                      _ProductLoadIssue(
                        message:
                            'Chưa thể tải thông tin gói Pro. Vui lòng thử '
                            'lại sau.',
                        onRetry: () => service.retryLoadProduct(),
                      )
                    else if (priceLabel == null &&
                        state.tier == SubscriptionTier.error &&
                        state.errorMessage != null)
                      _ProductLoadIssue(
                        message: state.errorMessage!,
                        onRetry: () => service.retryLoadProduct(),
                      )
                    else if (priceLabel == null)
                      const SizedBox(
                        height: 28,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            priceLabel,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/ năm',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tự động gia hạn hằng năm cho tới khi bạn huỷ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isPending || priceLabel == null
                      ? null
                      : () => service.buy(),
                  child: isPending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Nâng cấp lên Pro'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _restoring ? null : _restore,
                  child: Text(
                    _restoring
                        ? 'Đang khôi phục...'
                        : 'Khôi phục giao dịch mua',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaticInfoScreen(
                          title: 'Chính sách riêng tư',
                          body: kPrivacyPolicyText,
                        ),
                      ),
                    ),
                    child: const Text('Chính sách riêng tư'),
                  ),
                  const Text(
                    '·',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StaticInfoScreen(
                          title: 'Điều khoản sử dụng',
                          body: kTermsOfUseText,
                        ),
                      ),
                    ),
                    child: const Text('Điều khoản sử dụng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trạng thái "unavailable"/"error" của giá gói Pro — thay cho spinner vô
/// hạn khi query store đã hoàn tất nhưng không có kết quả (vd. product chưa
/// tồn tại trên App Store Connect/Play Console) hoặc lỗi mạng/store.
class _ProductLoadIssue extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProductLoadIssue({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.statusUnsurveyed,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
