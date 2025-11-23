import 'package:flutter/material.dart';

/// Navigation item configuration for bottom bar
class CustomBottomBarItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;

  const CustomBottomBarItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
  });
}

/// Custom bottom navigation bar for Pterodactyl mobile app
/// Implements bottom-heavy interaction design with thumb-reachable controls
/// Provides quick access to critical server management functions
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final List<CustomBottomBarItem>? customItems;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.customItems,
  });

  /// Default navigation items based on Mobile Navigation Hierarchy
  static final List<CustomBottomBarItem> _defaultItems = [
    const CustomBottomBarItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      route: '/server-dashboard',
    ),
    const CustomBottomBarItem(
      label: 'Console',
      icon: Icons.terminal_outlined,
      activeIcon: Icons.terminal,
      route: '/server-console',
    ),
    const CustomBottomBarItem(
      label: 'Files',
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      route: '/file-manager',
    ),
    const CustomBottomBarItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      route: '/server-settings',
    ),
    const CustomBottomBarItem(
      label: 'Backup',
      icon: Icons.backup_outlined,
      activeIcon: Icons.backup,
      route: '/backup-management',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? _defaultItems;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                context: context,
                item: items[index],
                index: index,
                isSelected: currentIndex == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required CustomBottomBarItem item,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor =
        theme.bottomNavigationBarTheme.unselectedItemColor ??
            colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!(index);
            } else {
              // Default navigation behavior
              Navigator.pushNamed(context, item.route);
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with smooth transition
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    key: ValueKey(isSelected),
                    color: isSelected ? selectedColor : unselectedColor,
                    size: 24.0,
                  ),
                ),
                const SizedBox(height: 1.0),
                // Label with color transition
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: (theme.bottomNavigationBarTheme.selectedLabelStyle ??
                          const TextStyle())
                      .copyWith(
                    color: isSelected ? selectedColor : unselectedColor,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Variant of CustomBottomBar with floating action button integration
/// Provides contextual quick actions for critical server operations
class CustomBottomBarWithFAB extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final VoidCallback? onFABPressed;
  final IconData? fabIcon;
  final String? fabTooltip;
  final List<CustomBottomBarItem>? customItems;

  const CustomBottomBarWithFAB({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.onFABPressed,
    this.fabIcon,
    this.fabTooltip,
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Bottom navigation bar
        CustomBottomBar(
          currentIndex: currentIndex,
          onTap: onTap,
          customItems: customItems,
        ),
        // Floating action button positioned above center
        Positioned(
          bottom: 32,
          child: FloatingActionButton(
            onPressed: onFABPressed,
            tooltip: fabTooltip ?? 'Quick Action',
            elevation: 4.0,
            backgroundColor: colorScheme.tertiary,
            foregroundColor: colorScheme.onTertiary,
            child: Icon(fabIcon ?? Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Compact variant for landscape or tablet layouts
class CustomBottomBarCompact extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  final List<CustomBottomBarItem>? customItems;

  const CustomBottomBarCompact({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? CustomBottomBar._defaultItems;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildCompactNavItem(
                context: context,
                item: items[index],
                index: index,
                isSelected: currentIndex == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavItem({
    required BuildContext context,
    required CustomBottomBarItem item,
    required int index,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor =
        theme.bottomNavigationBarTheme.unselectedItemColor ??
            colorScheme.onSurfaceVariant;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              onTap!(index);
            } else {
              Navigator.pushNamed(context, item.route);
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24.0,
            ),
          ),
        ),
      ),
    );
  }
}
