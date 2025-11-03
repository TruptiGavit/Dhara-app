import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/values/dimens.dart';
import 'package:dharak_flutter/res/values/gaps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:provider/provider.dart';
import 'package:dharak_flutter/app/tools/route/route_change_notifier.dart';

class ChatLandingPage extends StatefulWidget {
  const ChatLandingPage({super.key});

  @override
  State<ChatLandingPage> createState() => _ChatLandingPageState();
}

class _ChatLandingPageState extends State<ChatLandingPage> 
    with TickerProviderStateMixin {
  late AppThemeColors themeColors;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      
      // Set the current tab for the dashboard
      Provider.of<RouteChangeNotifier>(
        context,
        listen: false,
      ).updateTab(UiConstants.Tabs.chat);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    themeColors = Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.seedColor(seedColor: const Color(0xFF6CE18D), isDark: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Simple header - no search bar needed
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TdResDimens.dp_20,
                  vertical: TdResDimens.dp_16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.indigo,
                          size: 24,
                        ),
                        const SizedBox(width: TdResDimens.dp_12),
                        Text(
                          "AI Workspace",
                          style: TdResTextStyles.h4.copyWith(
                            color: themeColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TdResDimens.dp_20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome section - simple and clean
                      _buildSimpleWelcome(),
                      TdResGaps.v_32,
                      
                      // AI Tools - minimal design
                      _buildSimpleAITools(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleWelcome() {
    return Column(
      children: [
        // Dhara logo
        Image.asset(
          'assets/img/dhara_logo.png',
          height: 64,
          width: 64,
        ),
        TdResGaps.v_24,
        
        // Simple welcome message
        Text(
          "AI Assistant",
          style: TdResTextStyles.h2.copyWith(
            color: themeColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        TdResGaps.v_8,
        Text(
          "Choose your AI tool or ask anything above",
          style: TdResTextStyles.h6.copyWith(
            color: themeColors.onSurface?.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSimpleAITools() {
    return Column(
      children: [
        // AI Tools Grid - 2x2 layout for better use of space
        Row(
          children: [
            Expanded(
              child: _buildWorkspaceToolCard(
                title: "Ask Questions",
                subtitle: "Chat with AI",
                icon: Icons.chat_bubble_outline,
                color: Colors.indigo,
                isAvailable: true,
                onTap: () => _navigateToFeature(UiConstants.Routes.prashna),
              ),
            ),
            const SizedBox(width: TdResDimens.dp_16),
            Expanded(
              child: _buildWorkspaceToolCard(
                title: "Name Generator",
                subtitle: "Generate names",
                icon: Icons.label_important,
                color: Colors.purple,
                isAvailable: false,
                onTap: () => _showComingSoon("Name Generator"),
              ),
            ),
          ],
        ),
        const SizedBox(height: TdResDimens.dp_16),
        Row(
          children: [
            Expanded(
              child: _buildWorkspaceToolCard(
                title: "Essay Writer",
                subtitle: "Writing assistant",
                icon: Icons.edit_note,
                color: Colors.teal,
                isAvailable: false,
                onTap: () => _showComingSoon("Essay Writer"),
              ),
            ),
            const SizedBox(width: TdResDimens.dp_16),
            Expanded(
              child: _buildWorkspaceToolCard(
                title: "More Tools",
                subtitle: "Coming soon",
                icon: Icons.add_circle_outline,
                color: Colors.grey,
                isAvailable: false,
                onTap: () => _showComingSoon("More AI Tools"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkspaceToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(TdResDimens.dp_16),
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(TdResDimens.dp_16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TdResDimens.dp_16),
            border: Border.all(
              color: isAvailable 
                ? color.withOpacity(0.3) 
                : themeColors.onSurface?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
              width: 1.5,
            ),
            color: isAvailable 
              ? color.withOpacity(0.08) 
              : themeColors.onSurface?.withOpacity(0.02),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TdResDimens.dp_8),
                    decoration: BoxDecoration(
                      color: (isAvailable ? color : Colors.grey).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(TdResDimens.dp_8),
                    ),
                    child: Icon(
                      icon,
                      color: isAvailable ? color : Colors.grey,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TdResDimens.dp_6,
                        vertical: TdResDimens.dp_2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TdResDimens.dp_4),
                      ),
                      child: Text(
                        "Soon",
                        style: TdResTextStyles.caption.copyWith(
                          color: Colors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              
              // Title and subtitle
              Text(
                title,
                style: TdResTextStyles.h6.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: TdResDimens.dp_2),
              Text(
                subtitle,
                style: TdResTextStyles.caption.copyWith(
                  color: themeColors.onSurface?.withOpacity(0.6),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _navigateToFeature(String route) {
    // Navigate to AI tool
    Modular.to.pushNamed(UiConstants.Routes.getRoutePath(route));
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature - Coming Soon!"),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
