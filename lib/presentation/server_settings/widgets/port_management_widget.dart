import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Port management widget with add/remove capabilities
class PortManagementWidget extends StatelessWidget {
  final List<Map<String, dynamic>> ports;
  final VoidCallback onAddPort;
  final Function(int) onRemovePort;

  const PortManagementWidget({
    super.key,
    required this.ports,
    required this.onAddPort,
    required this.onRemovePort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Network Ports',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'add_circle',
                color: colorScheme.primary,
                size: 24,
              ),
              onPressed: onAddPort,
              tooltip: 'Add Port',
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ports.length,
          itemBuilder: (context, index) {
            final port = ports[index];
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: ListTile(
                leading: CustomIconWidget(
                  iconName: 'settings_ethernet',
                  color: colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  'Port ${port["port"]}',
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  port["protocol"] as String,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: CustomIconWidget(
                    iconName: 'delete',
                    color: colorScheme.error,
                    size: 20,
                  ),
                  onPressed: () => onRemovePort(index),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 2.h),
      ],
    );
  }
}
