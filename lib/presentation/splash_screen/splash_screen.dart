import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'package:pterodactyl_app/data/services/settings_service.dart';

/// Splash Screen for Pterodactyl Mobile Application
/// Provides branded launch experience while initializing API connections
/// and determining user authentication status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isInitializing = true;
  String _statusMessage = 'Connecting to servers...';
  bool _hasError = false;
  bool _canRetry = false;
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      final hasRequiredSettings = await _settingsService.hasRequiredSettings();
      if (!hasRequiredSettings) {
        _navigateToNextScreen(isAuthenticated: false);
        return;
      }
      
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Validating credentials...';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Loading server data...';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Preparing connections...';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      _navigateToNextScreen();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _statusMessage = 'Connection failed';
        _isInitializing = false;
      });

      // Show retry button after 5 seconds
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() {
        _canRetry = true;
      });
    }
  }

  void _navigateToNextScreen({bool isAuthenticated = true}) {
    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/server-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.settings);
    }
  }

  void _retryConnection() {
    setState(() {
      _hasError = false;
      _canRetry = false;
      _isInitializing = true;
      _statusMessage = 'Connecting to servers...';
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer,
                colorScheme.secondary.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo with animations
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLogo(colorScheme),
                  ),
                ),

                SizedBox(height: 6.h),

                // Status message
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildStatusSection(theme, colorScheme),
                  ),
                ),

                const Spacer(flex: 3),

                // Retry button (if error occurred)
                if (_hasError && _canRetry)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: _buildRetryButton(theme, colorScheme),
                  ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pterodactyl wing icon with subtle animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -2 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 25.w,
                      height: 25.w,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: 3.h),

        // App name
        Text(
          'Pterodactyl',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            letterSpacing: 1.2,
          ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Mobile Panel',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12.sp,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator or error icon
        if (_isInitializing)
          SizedBox(
            width: 8.w,
            height: 8.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.9),
              ),
            ),
          )
        else if (_hasError)
          CustomIconWidget(
            iconName: 'error_outline',
            size: 8.w,
            color: AppTheme.errorLight,
          )
        else
          CustomIconWidget(
            iconName: 'check_circle_outline',
            size: 8.w,
            color: AppTheme.successLight,
          ),

        SizedBox(height: 2.h),

        // Status message
        Text(
          _statusMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 11.sp,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),

        if (_hasError && !_canRetry) ...[
          SizedBox(height: 1.h),
          Text(
            'Retry available in a moment...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRetryButton(ThemeData theme, ColorScheme colorScheme) {
    return ElevatedButton.icon(
      onPressed: _retryConnection,
      icon: CustomIconWidget(
        iconName: 'refresh',
        size: 5.w,
        color: colorScheme.primary,
      ),
      label: Text(
        'Retry Connection',
        style: theme.textTheme.labelLarge?.copyWith(
          fontSize: 11.sp,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(
          horizontal: 8.w,
          vertical: 1.5.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 4.0,
      ),
    );
  }
}