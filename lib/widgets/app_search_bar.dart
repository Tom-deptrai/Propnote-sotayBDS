import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final Widget? trailing;
  final bool elevated;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.trailing,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: elevated ? null : Border.all(color: AppColors.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ?trailing,
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
