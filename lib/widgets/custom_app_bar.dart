import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pterodactyl_app/routes/app_routes.dart';

/// Custom app bar variants for different screen contexts
enum CustomAppBarVariant {
  /// Standard app bar with title and actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with connection status indicator
  withStatus,

  /// Transparent app bar for scrollable content
  transparent,
}

/// Custom app bar for Pterodactyl mobile app
/// Implements clean, minimal design with contextual actions
/// Provides consistent navigation and status visibility
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final CustomAppBarVariant variant;
  final VoidCallback? onSearchPressed;
  final bool showConnectionStatus;
  final bool isConnected;
  final double elevation;
  final Color? backgroundColor;
  final bool centerTitle;
  final TextStyle titleTextStyle;
  final bool showSettingsButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.variant = CustomAppBarVariant.standard,
    this.onSearchPressed,
    this.showConnectionStatus = false,
    this.isConnected = true,
    this.elevation = 2.0,
    this.backgroundColor,
    this.centerTitle = false,
    this.titleTextStyle =
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    this.showSettingsButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case CustomAppBarVariant.search:
        return _buildSearchAppBar(context, theme, colorScheme);
      case CustomAppBarVariant.withStatus:
        return _buildStatusAppBar(context, theme, colorScheme);
      case CustomAppBarVariant.transparent:
        return _buildTransparentAppBar(context, theme, colorScheme);
      case CustomAppBarVariant.standard:
        return _buildStandardAppBar(context, theme, colorScheme);
    }
  }

  Widget _buildStandardAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: _buildActions(context, theme, colorScheme),
      elevation: elevation,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: centerTitle,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  Widget _buildSearchAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final searchBar = _buildSearchBar(context, theme, colorScheme);
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: searchBar,
      actions: _buildActions(context, theme, colorScheme),
      elevation: elevation,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Widget _buildStatusAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: Row(
        children: [
          if (showConnectionStatus) ...[
            _buildConnectionStatus(context, theme, colorScheme),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: titleWidget ??
                (title != null
                    ? Text(title!, style: titleTextStyle)
                    : const SizedBox()),
          ),
        ],
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: _buildActions(context, theme, colorScheme),
      elevation: elevation,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
    );
  }

  Widget _buildTransparentAppBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: _buildActions(context, theme, colorScheme),
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      centerTitle: centerTitle,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            theme.brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    List<Widget> allActions = [];

    if (actions != null) {
      allActions.addAll(actions!);
    }

    if (showSettingsButton) {
      allActions.add(
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          tooltip: 'Settings',
        ),
      );
    }

    return allActions;
  }

  Widget _buildConnectionStatus(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final statusColor = isConnected
        ? (theme.brightness == Brightness.light
            ? const Color(0xFF059669)
            : const Color(0xFF10B981))
        : (theme.brightness == Brightness.light
            ? const Color(0xFFDC2626)
            : const Color(0xFFEF4444));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: onSearchPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colorScheme.onPrimary.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text(
              'Search servers...',
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver variant of CustomAppBar for use in scrollable content
class CustomSliverAppBar extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final double elevation;
  final Color? backgroundColor;

  const CustomSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight = 120.0,
    this.flexibleSpace,
    this.elevation = 2.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      flexibleSpace: flexibleSpace,
      elevation: elevation,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }
}

/// App bar with integrated search field
class CustomSearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onClearPressed;
  final List<Widget>? actions;
  final bool autofocus;

  const CustomSearchAppBar({
    super.key,
    this.hintText,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClearPressed,
    this.actions,
    this.autofocus = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomSearchAppBar> createState() => _CustomSearchAppBarState();
}

class _CustomSearchAppBarState extends State<CustomSearchAppBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search...',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    if (widget.onClearPressed != null) {
                      widget.onClearPressed!();
                    }
                    if (widget.onSearchChanged != null) {
                      widget.onSearchChanged!('');
                    }
                  },
                )
              : null,
        ),
        style: theme.textTheme.bodyLarge,
        onChanged: (value) {
          setState(() {});
          if (widget.onSearchChanged != null) {
            widget.onSearchChanged!(value);
          }
        },
        onSubmitted: (value) {
          if (widget.onSearchSubmitted != null) {
            widget.onSearchSubmitted!();
          }
        },
      ),
      actions: widget.actions,
      elevation: 2.0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
    );
  }
}
