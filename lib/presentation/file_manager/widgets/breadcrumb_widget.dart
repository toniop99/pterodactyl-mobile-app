import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Breadcrumb navigation widget showing current directory path
class BreadcrumbWidget extends StatelessWidget {
  final List<String> pathSegments;
  final Function(int) onSegmentTap;

  const BreadcrumbWidget({
    super.key,
    required this.pathSegments,
    required this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home Icon
            InkWell(
              onTap: () => onSegmentTap(0),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                child: CustomIconWidget(
                  iconName: 'home',
                  color: colorScheme.primary,
                  size: 5.w,
                ),
              ),
            ),
            // Path Segments
            ...List.generate(pathSegments.length, (index) {
              final isLast = index == pathSegments.length - 1;
              return Row(
                children: [
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: colorScheme.onSurfaceVariant,
                    size: 4.w,
                  ),
                  InkWell(
                    onTap: isLast ? null : () => onSegmentTap(index + 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: isLast
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pathSegments[index],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLast
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight:
                              isLast ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
