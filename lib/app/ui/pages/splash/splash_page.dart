import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:dharak_flutter/res/theme/theme_helper.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  late AppThemeColors themeColors;
  late AppThemeDisplay appThemeDisplay;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _scaleController.forward();
      _checkAuthenticationState();
    });
  }

  Future<void> _checkAuthenticationState() async {
    try {
      // Add some delay for splash effect
      await Future.delayed(const Duration(milliseconds: 1500));

      
      // Check if onboarding is completed
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
      
      
      if (!hasCompletedOnboarding) {
        if (mounted) {
          Modular.to.pushReplacementNamed('/onboarding');
        }
        return;
      }
      
      final authRepo = Modular.get<AuthAccountRepository>();
      authRepo.initSetup();
      
      // Wait a bit for repository initialization
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check for valid authentication
      final accessToken = await authRepo.mSecureStorage.getAccessToken();
      var user = authRepo.mAccountUserObservable.value;
      
      bool isAuthenticated = accessToken != null && 
                           accessToken.isNotEmpty &&
                           user != null && 
                           (user.email?.isNotEmpty == true || 
                            user.name?.isNotEmpty == true);
      
      
      if (mounted) {
        if (isAuthenticated) {
          Modular.to.pushReplacementNamed('/Dhara/quicksearch');
        } else {
          _logger.d("SplashPage: User not authenticated, navigating to login");
          Modular.to.pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      _logger.e("SplashPage: Error checking authentication state: $e");
      
      if (mounted) {
        // On error, navigate to login for safety
        _logger.d("SplashPage: Error occurred, navigating to login");
        Modular.to.pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _prepareTheme(context);
    
    return Scaffold(
      backgroundColor: themeColors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: themeColors.surface,
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: themeColors.onSurface.withOpacity(0.15),
                              blurRadius: 25,
                              offset: Offset(0, 12),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(TdResDimens.dp_20),
                        child: Image.asset(
                          "assets/img/Dhara_logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              TdResGaps.v_40,
              
              // App name with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Dhārā',
                  style: TdResTextStyles.h1Bold.copyWith(
                    color: TdResColors.colorDharaBlue,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              TdResGaps.v_16,
              
              // Tagline with delayed fade
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'AI Powered Search',
                  style: TdResTextStyles.h2SemiBold.copyWith(
                    color: themeColors.onSurface.withOpacity(0.8),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              TdResGaps.v_60,
              
              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      TdResColors.colorDharaBlue.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
              
              TdResGaps.v_24,
              
              // Loading text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Initializing...',
                  style: TdResTextStyles.p1.copyWith(
                    color: themeColors.onSurface.withOpacity(0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logger.d("SplashPage: Disposing...");
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _prepareTheme(BuildContext context) {
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: Theme.of(context).brightness == Brightness.dark);
    appThemeDisplay = Theme.of(context).extension<AppThemeDisplay>() ??
        TdThemeHelper.prepareThemeDisplay(context);
  }
}