import 'package:flutter/material.dart';

import '../../../data/services/storage_usage_service.dart';
import '../../../theme/app_colors.dart';
import 'settings_tile.dart';

/// Hàng "Dung lượng đang sử dụng" trong Settings. Tự quản lý Future riêng
/// (tạo 1 lần trong `initState`, không tạo lại mỗi khi SettingsScreen rebuild
/// do AppState đổi) để tránh việc phép tính không bao giờ có cơ hội hoàn
/// thành trước khi bị thay bằng 1 Future mới.
class StorageUsageTile extends StatefulWidget {
  final StorageUsageService service;

  const StorageUsageTile({super.key, required this.service});

  @override
  State<StorageUsageTile> createState() => _StorageUsageTileState();
}

class _StorageUsageTileState extends State<StorageUsageTile> {
  late Future<StorageUsage> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.compute();
  }

  void _retry() {
    setState(() {
      _future = widget.service.compute();
    });
  }

  void _showBreakdown(StorageUsage usage) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dung lượng đang sử dụng',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _BreakdownRow(
                label: 'Dữ liệu PropNote',
                bytes: usage.appDataBytes,
              ),
              const SizedBox(height: 10),
              _BreakdownRow(label: 'Bản đồ offline', bytes: usage.mapBytes),
              const Divider(height: 28),
              _BreakdownRow(
                label: 'Tổng cộng',
                bytes: usage.totalBytes,
                emphasize: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StorageUsage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SettingsTile(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Dung lượng đang sử dụng',
            trailingText: 'Đang tính...',
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return SettingsTile(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Dung lượng đang sử dụng',
            trailingWidget: const Text(
              'Không thể tính',
              style: TextStyle(color: AppColors.textTertiary),
            ),
            onTap: _retry,
          );
        }
        final usage = snapshot.data!;
        return SettingsTile(
          icon: Icons.pie_chart_outline_rounded,
          label: 'Dung lượng đang sử dụng',
          trailingText: formatStorageBytes(usage.totalBytes),
          onTap: () => _showBreakdown(usage),
        );
      },
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int bytes;
  final bool emphasize;

  const _BreakdownRow({
    required this.label,
    required this.bytes,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasize ? 15 : 14,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
      color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(formatStorageBytes(bytes), style: style),
      ],
    );
  }
}
