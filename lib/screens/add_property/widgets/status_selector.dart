import 'package:flutter/material.dart';

import '../../../models/property_status.dart';
import '../../../theme/app_colors.dart';

class StatusSelector extends StatelessWidget {
  final PropertyStatus selected;
  final ValueChanged<PropertyStatus> onChanged;

  const StatusSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PropertyStatus.values.map((status) {
        final isSelected = status == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: status == PropertyStatus.values.last ? 0 : 8,
            ),
            child: InkWell(
              onTap: () => onChanged(status),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? status.bgColor : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? status.color : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? status.color
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
