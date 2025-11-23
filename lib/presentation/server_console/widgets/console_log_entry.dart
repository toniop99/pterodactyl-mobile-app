import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Individual log entry widget with timestamp and color-coded message
class ConsoleLogEntry extends StatelessWidget {
  final String timestamp;
  final String message;
  final String type; // 'info', 'warning', 'error', 'player', 'system'
  final VoidCallback? onLongPress;

  const ConsoleLogEntry({
    super.key,
    required this.timestamp,
    required this.message,
    required this.type,
    this.onLongPress,
  });

  Color _getMessageColor(BuildContext context, String type) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    switch (type.toLowerCase()) {
      case 'error':
        return isLight ? AppTheme.errorLight : AppTheme.errorDark;
      case 'warning':
        return isLight ? AppTheme.warningLight : AppTheme.warningDark;
      case 'player':
        return isLight ? AppTheme.primaryLight : AppTheme.primaryDark;
      case 'system':
        return isLight ? AppTheme.secondaryLight : AppTheme.secondaryDark;
      case 'info':
      default:
        return isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messageColor = _getMessageColor(context, type);

    return GestureDetector(
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress!();
        } else {
          Clipboard.setData(ClipboardData(text: message));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log entry copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 1.w),
            Expanded(
              child: Text(
                message,
                style: AppTheme.getMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ).copyWith(
                  color: messageColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
