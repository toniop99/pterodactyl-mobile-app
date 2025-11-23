import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pterodactyl_app/data/models/server_model.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Individual server card widget displaying server information and status
class ServerCardWidget extends StatelessWidget {
  final Map<String, dynamic> server;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onViewLogs;
  final VoidCallback onBackup;
  final VoidCallback onSettings;

  const ServerCardWidget({
    super.key,
    required this.server,
    required this.onTap,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onViewLogs,
    required this.onBackup,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = server['status'].toString();
    final isOnline = status.toLowerCase() == ServerStatus.running.value;
    final isStarting = status.toLowerCase() == ServerStatus.starting.value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(server['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onStart(),
              backgroundColor: AppTheme.successLight,
              foregroundColor: Colors.white,
              icon: Icons.play_arrow,
              label: 'Start',
            ),
            SlidableAction(
              onPressed: (_) => onStop(),
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
              icon: Icons.stop,
              label: 'Stop',
            ),
            SlidableAction(
              onPressed: (_) => onRestart(),
              backgroundColor: AppTheme.warningLight,
              foregroundColor: Colors.white,
              icon: Icons.refresh,
              label: 'Restart',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onViewLogs(),
              backgroundColor: colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: Icons.article,
              label: 'Logs',
            ),
            SlidableAction(
              onPressed: (_) => onBackup(),
              backgroundColor: colorScheme.tertiary,
              foregroundColor: Colors.white,
              icon: Icons.backup,
              label: 'Backup',
            ),
            SlidableAction(
              onPressed: (_) => onSettings(),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.settings,
              label: 'Settings',
            ),
          ],
        ),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: () => _showContextMenu(context),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, colorScheme, isOnline, isStarting),
                  SizedBox(height: 2.h),
                  _buildUpTimeInfo(theme),
                  SizedBox(height: 2.h),
                  _buildResourceUsage(theme, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, bool isOnline,
      bool isStarting) {
    return Row(
      children: [
        CustomImageWidget(
          imageUrl: server['gameIcon'] as String,
          width: 12.w,
          height: 12.w,
          fit: BoxFit.cover,
          semanticLabel: server['gameIconLabel'] as String,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                server['name'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Text(
                server['gameType'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(theme, colorScheme, isOnline, isStarting),
      ],
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, ColorScheme colorScheme,
      bool isOnline, bool isStarting) {
    final statusColor = isOnline
        ? AppTheme.successLight
        : isStarting
            ? AppTheme.warningLight
            : AppTheme.errorLight;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            server['status'].toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpTimeInfo(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 4.w,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 2.w),
        Text(
          'Uptime: ${server['uptime']}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceUsage(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildResourceBar(
          theme,
          colorScheme,
          'CPU',
          server['cpuUsage'] as double,
          AppTheme.primaryLight,
        ),
        SizedBox(height: 1.h),
        _buildResourceBar(
          theme,
          colorScheme,
          'RAM',
          server['ramUsage'] as double,
          AppTheme.warningLight,
        ),
      ],
    );
  }

  Widget _buildResourceBar(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.h,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'play_arrow',
                color: AppTheme.successLight,
              ),
              title: const Text('Start Server'),
              onTap: () {
                Navigator.pop(context);
                onStart();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'stop',
                color: AppTheme.errorLight,
              ),
              title: const Text('Stop Server'),
              onTap: () {
                Navigator.pop(context);
                onStop();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.warningLight,
              ),
              title: const Text('Restart Server'),
              onTap: () {
                Navigator.pop(context);
                onRestart();
              },
            ),
            const Divider(),
            ListTile(
              leading: const CustomIconWidget(iconName: 'article'),
              title: const Text('View Logs'),
              onTap: () {
                Navigator.pop(context);
                onViewLogs();
              },
            ),
            ListTile(
              leading: const CustomIconWidget(iconName: 'backup'),
              title: const Text('Create Backup'),
              onTap: () {
                Navigator.pop(context);
                onBackup();
              },
            ),
            ListTile(
              leading: const CustomIconWidget(iconName: 'settings'),
              title: const Text('Server Settings'),
              onTap: () {
                Navigator.pop(context);
                onSettings();
              },
            ),
          ],
        ),
      ),
    );
  }
}
