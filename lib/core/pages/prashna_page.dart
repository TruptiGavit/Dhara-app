import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/styles/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class PrashnaPage extends StatefulWidget {
  const PrashnaPage({Key? key}) : super(key: key);

  @override
  State<PrashnaPage> createState() => _PrashnaPageState();
}

class _PrashnaPageState extends State<PrashnaPage> {
  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>()!;
    
    return Scaffold(
      backgroundColor: themeColors.surface,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Chat Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Prashna - AI Chat',
                style: TdResTextStyles.h1.copyWith(
                  color: themeColors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Coming Soon! 🚀',
                style: TdResTextStyles.h3.copyWith(
                  color: themeColors.onSurface.withOpacity(0.7),
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColors.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeColors.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Interactive AI chat experience for deeper conversations about Sanskrit texts, philosophy, and spiritual wisdom.',
                      style: TdResTextStyles.p1.copyWith(
                        color: themeColors.onSurface.withOpacity(0.8),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Features
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeature(
                          icon: Icons.chat_bubble_outline,
                          label: 'Smart AI',
                          themeColors: themeColors,
                        ),
                        _buildFeature(
                          icon: Icons.book,
                          label: 'Context Aware',
                          themeColors: themeColors,
                        ),
                        _buildFeature(
                          icon: Icons.chat,
                          label: 'Natural Chat',
                          themeColors: themeColors,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Back to QuickSearch button
              ElevatedButton(
                onPressed: () {
                  // Navigate back to QuickSearch
                  Modular.to.navigate('/quicksearch');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Try QuickSearch',
                      style: TdResTextStyles.p1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature({
    required IconData icon,
    required String label,
    required AppThemeColors themeColors,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TdResTextStyles.caption.copyWith(
            color: themeColors.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
