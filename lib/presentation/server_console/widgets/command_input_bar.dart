import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Command input bar with send button and loading state
class CommandInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback? onHistoryUp;
  final VoidCallback? onHistoryDown;

  const CommandInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    this.onHistoryUp,
    this.onHistoryDown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (onHistoryUp != null || onHistoryDown != null)
              Container(
                margin: EdgeInsets.only(right: 1.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onHistoryUp != null)
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'keyboard_arrow_up',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: onHistoryUp,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (onHistoryDown != null)
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'keyboard_arrow_down',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: onHistoryDown,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                style: AppTheme.getMonospaceStyle(
                  isLight: theme.brightness == Brightness.light,
                  fontSize: 13.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter command...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                ),
                onSubmitted: (_) => isLoading ? null : onSend(),
              ),
            ),
            SizedBox(width: 2.w),
            Container(
              width: 12.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isLoading
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : onSend,
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'send',
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
