import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// Quick action buttons for common commands
class QuickActionButtons extends StatelessWidget {
  final Function(String) onCommandSelected;
  final bool isEnabled;

  const QuickActionButtons({
    super.key,
    required this.onCommandSelected,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, String>> quickCommands = [
      {'label': 'say', 'command': 'say '},
      {'label': 'add whitelist', 'command': 'easywhitelist add '},
      {'label': 'list', 'command': 'list'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: quickCommands.map((cmd) {
            return Container(
              height: 5.h,
              margin: EdgeInsets.only(right: 1.w),
              child: OutlinedButton(
                onPressed:
                    isEnabled ? () => onCommandSelected(cmd['command']!) : null,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  side: BorderSide(
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  cmd['label']!,
                  style: AppTheme.getMonospaceStyle(
                    isLight: theme.brightness == Brightness.light,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ).copyWith(
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
