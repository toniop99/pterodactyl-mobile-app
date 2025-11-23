import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog for file upload options
class FileUploadDialog extends StatelessWidget {
  final VoidCallback onSelectFile;
  final VoidCallback onTakePhoto;
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateFile;

  const FileUploadDialog({
    super.key,
    required this.onSelectFile,
    required this.onTakePhoto,
    required this.onCreateFolder,
    required this.onCreateFile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildOption(
              context,
              icon: 'upload_file',
              label: 'Upload File',
              onTap: () {
                Navigator.pop(context);
                onSelectFile();
              },
            ),
            SizedBox(height: 1.h),
            _buildOption(
              context,
              icon: 'camera_alt',
              label: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                onTakePhoto();
              },
            ),
            SizedBox(height: 1.h),
            _buildOption(
              context,
              icon: 'create_new_folder',
              label: 'New Folder',
              onTap: () {
                Navigator.pop(context);
                onCreateFolder();
              },
            ),
            SizedBox(height: 1.h),
            _buildOption(
              context,
              icon: 'note_add',
              label: 'New File',
              onTap: () {
                Navigator.pop(context);
                onCreateFile();
              },
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: colorScheme.primary,
                  size: 6.w,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
