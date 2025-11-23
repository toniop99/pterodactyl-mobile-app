import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Banner showing connection status and offline mode
class ConnectionStatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool isReconnecting;
  final VoidCallback? onRetry;

  const ConnectionStatusBanner({
    super.key,
    required this.isConnected,
    this.isReconnecting = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (isConnected && !isReconnecting) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: isReconnecting
            ? (isLight ? AppTheme.warningLight : AppTheme.warningDark)
            : (isLight ? AppTheme.errorLight : AppTheme.errorDark),
      ),
      child: Row(
        children: [
          if (isReconnecting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onError,
                ),
              ),
            )
          else
            CustomIconWidget(
              iconName: 'cloud_off',
              color: theme.colorScheme.onError,
              size: 20,
            ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              isReconnecting
                  ? 'Reconnecting to server...'
                  : 'Live connection unavailable',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isReconnecting && onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onError,
                padding: EdgeInsets.symmetric(horizontal: 3.w),
              ),
              child: Text(
                'Retry',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
