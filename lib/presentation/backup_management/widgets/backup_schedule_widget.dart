import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Backup schedule configuration widget
class BackupScheduleWidget extends StatelessWidget {
  final String frequency;
  final int retentionDays;
  final VoidCallback onEdit;

  const BackupScheduleWidget({
    super.key,
    required this.frequency,
    required this.retentionDays,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'schedule',
                color: colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Automated Backup Schedule',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: CustomIconWidget(
                  iconName: 'edit',
                  color: colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'Edit Schedule',
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildScheduleItem(
            context,
            'Frequency',
            _getFrequencyText(frequency),
            Icons.repeat,
          ),
          SizedBox(height: 1.h),
          _buildScheduleItem(
            context,
            'Retention',
            '$retentionDays days',
            Icons.history,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        CustomIconWidget(
          iconName: icon
              .toString()
              .split('.')
              .last
              .replaceAll('IconData(U+', '')
              .replaceAll(')', ''),
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Every day at 2:00 AM';
      case 'weekly':
        return 'Every Sunday at 2:00 AM';
      case 'custom':
        return 'Custom schedule';
      default:
        return frequency;
    }
  }
}
