import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Trạng thái của một bất động sản trong sổ tay.
enum PropertyStatus { selling, unsurveyed, sold }

extension PropertyStatusX on PropertyStatus {
  String get label {
    switch (this) {
      case PropertyStatus.unsurveyed:
        return 'Chưa khảo sát';
      case PropertyStatus.selling:
        return 'Đang bán';
      case PropertyStatus.sold:
        return 'Đã bán';
    }
  }

  Color get color {
    switch (this) {
      case PropertyStatus.unsurveyed:
        return AppColors.statusUnsurveyed;
      case PropertyStatus.selling:
        return AppColors.statusSelling;
      case PropertyStatus.sold:
        return AppColors.statusSold;
    }
  }

  Color get bgColor {
    switch (this) {
      case PropertyStatus.unsurveyed:
        return AppColors.statusUnsurveyedBg;
      case PropertyStatus.selling:
        return AppColors.statusSellingBg;
      case PropertyStatus.sold:
        return AppColors.statusSoldBg;
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyStatus.unsurveyed:
        return Icons.radio_button_unchecked_rounded;
      case PropertyStatus.selling:
        return Icons.sell_rounded;
      case PropertyStatus.sold:
        return Icons.check_circle_rounded;
    }
  }
}
