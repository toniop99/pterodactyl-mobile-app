import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Individual file/folder item widget with swipe actions
class FileItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onMove;
  final VoidCallback onPermissions;
  final VoidCallback onProperties;
  final bool isSelected;

  const FileItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDownload,
    required this.onShare,
    required this.onRename,
    required this.onDelete,
    required this.onCopy,
    required this.onMove,
    required this.onPermissions,
    required this.onProperties,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFolder = item['type'] == 'folder';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // File/Folder Icon
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: _getIconColor(colorScheme, isFolder)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: _getIconName(isFolder),
                      color: _getIconColor(colorScheme, isFolder),
                      size: 6.w,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                // File Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          if (!isFolder) ...[
                            Text(
                              item['size'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          Text(
                            item['modified'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Quick Action Button
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'more_vert',
                    color: colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  onPressed: () => _showContextMenu(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getIconName(bool isFolder) {
    if (isFolder) return 'folder';
    final extension = (item['name'] as String).split('.').last.toLowerCase();
    switch (extension) {
      case 'txt':
      case 'log':
        return 'description';
      case 'json':
      case 'yml':
      case 'yaml':
      case 'properties':
        return 'code';
      case 'jar':
      case 'zip':
        return 'archive';
      case 'png':
      case 'jpg':
      case 'jpeg':
        return 'image';
      default:
        return 'insert_drive_file';
    }
  }

  Color _getIconColor(ColorScheme colorScheme, bool isFolder) {
    if (isFolder) return colorScheme.primary;
    final extension = (item['name'] as String).split('.').last.toLowerCase();
    switch (extension) {
      case 'txt':
      case 'log':
        return const Color(0xFF64748B);
      case 'json':
      case 'yml':
      case 'yaml':
      case 'properties':
        return const Color(0xFF3B82F6);
      case 'jar':
      case 'zip':
        return const Color(0xFFD97706);
      case 'png':
      case 'jpg':
      case 'jpeg':
        return const Color(0xFF059669);
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: Text(
                item['name'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            _buildMenuItem(context, 'download', 'Download', onDownload),
            _buildMenuItem(context, 'share', 'Share', onShare),
            _buildMenuItem(context, 'edit', 'Rename', onRename),
            _buildMenuItem(context, 'content_copy', 'Copy', onCopy),
            _buildMenuItem(context, 'drive_file_move', 'Move', onMove),
            _buildMenuItem(context, 'lock', 'Permissions', onPermissions),
            _buildMenuItem(context, 'info', 'Properties', onProperties),
            const Divider(height: 1),
            _buildMenuItem(
              context,
              'delete',
              'Delete',
              onDelete,
              isDestructive: true,
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: isDestructive
            ? (theme.brightness == Brightness.light
                ? const Color(0xFFDC2626)
                : const Color(0xFFEF4444))
            : colorScheme.onSurface,
        size: 5.w,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDestructive
              ? (theme.brightness == Brightness.light
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFEF4444))
              : colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
