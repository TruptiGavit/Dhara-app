import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:dharak_flutter/res/values/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎨 Beautiful Onboarding Screen for Dhārā App
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  AppThemeColors get themeColors =>
      Theme.of(context).extension<AppThemeColors>() ??
      AppThemeColors.seedColor(
        seedColor: TdResColors.colorPrimary40,
        isDark: false,
      );

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      title: 'Welcome to Dhārā',
      subtitle: 'AI Powered Search',
      description: 'Discover ancient wisdom through modern technology. Dhārā brings you comprehensive Indic knowledge at your fingertips.',
      icon: Icons.auto_awesome,
      color: TdResColors.colorDharaBlue, // Use Dhārā brand color
      lottieAsset: null,
      logoAsset: "assets/img/Dhara_logo.png", // Add Dhārā logo for first page
    ),
    OnboardingItem(
      title: 'Shodh (शोध)',
      subtitle: 'Classic Search boosted by AI',
      description: 'Ask a question or phrase to get list of relevant pages from Indic books, verses and dictionaries',
      icon: Icons.electric_bolt, // More relevant search icon
      color: Color(0xFFFF6B35), // Orange for unified search
      lottieAsset: null,
    ),
    OnboardingItem(
      title: 'Prashna (प्रश्न)',
      subtitle: 'AI Chatbot',
      description: 'Ask questions or chat to get AI-generated answers, with supporting evidence, facts and references',
      icon: Icons.chat_bubble_outline, // Chat-specific icon
      color: Color(0xFF7986CB), // Indigo for Prashna
      lottieAsset: null,
    ),
    OnboardingItem(
      title: 'Dhārā is still in Beta',
      subtitle: 'Please help us improve 🙏',
      description: 'Whenever you find a bug, press the email icon to send us a message on WhatsApp or e-mail',
      icon: Icons.attach_email_rounded, // Email icon for messaging
      color: Color(0xFFE53E3E), // Red for bug reporting
      lottieAsset: null,
    ),
    OnboardingItem(
      title: 'Start Your Journey',
      subtitle: 'Begin Exploring Indic Knowledge',
      description: 'Ready to embark on your Indic learning journey? Sign in to access personalized features and save your favorite content.',
      icon: Icons.explore, // More relevant exploration icon
      color: TdResColors.colorDharaBlue, // Back to brand color
      lottieAsset: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColors.surface,
              themeColors.surface.withOpacity(0.95),
              themeColors.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with logo and skip button
              _buildTopBar(),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingItems.length,
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_onboardingItems[index]);
                  },
                ),
              ),
              
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _onboardingItems.asMap().entries.map((entry) {
                  return _buildPageIndicator(entry.key);
                }).toList(),
              ),
              
              TdResGaps.v_32,
              
              // Bottom navigation
              _buildBottomNavigation(),
              
              TdResGaps.v_24,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.all(TdResDimens.dp_16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Text(
            'Dhārā',
            style: TdResTextStyles.h2SemiBold.copyWith(
              color: TdResColors.colorDharaBlue,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          // Skip button
          if (_currentPage < _onboardingItems.length - 1)
            TextButton(
              onPressed: () => _finishOnboarding(),
              child: Text(
                'Skip',
                style: TdResTextStyles.p1.copyWith(
                  color: themeColors.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_32),
      child: Column(
        children: [
          TdResGaps.v_24, // Reduced from v_32
          
          // Icon/Illustration or Logo
          Container(
            width: 100, // Reduced from 120
            height: 100, // Reduced from 120
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25), // Adjusted proportionally
              border: Border.all(
                color: item.color.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: item.logoAsset != null
                ? Padding(
                    padding: const EdgeInsets.all(12), // Reduced from 16
                    child: Image.asset(
                      item.logoAsset!,
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(
                    item.icon,
                    size: 50, // Reduced from 60
                    color: item.color,
                  ),
          ),
          
          TdResGaps.v_24, // Reduced from v_40
          
          // Title
          Text(
            item.title,
            style: TdResTextStyles.h1Bold.copyWith(
              color: themeColors.onSurface,
              fontSize: 28, // Reduced from 32
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          
          TdResGaps.v_12, // Reduced from v_16
          
          // Subtitle
          Text(
            item.subtitle,
            style: TdResTextStyles.h3.copyWith(
              color: item.color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          TdResGaps.v_16, // Reduced from v_24
          
          // Description - wrapped in Expanded to take remaining space
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                item.description,
                style: TdResTextStyles.p1.copyWith(
                  color: themeColors.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: TdResDimens.dp_32),
      child: Row(
        children: [
          // Previous button (only show after first page)
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_16),
                  side: BorderSide(
                    color: themeColors.primary,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TdResTextStyles.button.copyWith(
                    color: themeColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          if (_currentPage > 0) TdResGaps.h_16,
          
          // Next/Get Started button with gradient
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _onboardingItems[_currentPage].color,
                    _onboardingItems[_currentPage].color.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _onboardingItems[_currentPage].color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage == _onboardingItems.length - 1) {
                    _finishOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: TdResDimens.dp_16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  _currentPage == _onboardingItems.length - 1 
                      ? 'Get Started' 
                      : 'Next',
                  style: TdResTextStyles.button.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    final item = _onboardingItems[index];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? item.color : item.color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Navigate to login
    if (mounted) {
      Modular.to.pushReplacementNamed('/login');
    }
  }
}

/// Data model for onboarding items
class OnboardingItem {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String? lottieAsset;
  final String? logoAsset;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    this.lottieAsset,
    this.logoAsset,
  });
}