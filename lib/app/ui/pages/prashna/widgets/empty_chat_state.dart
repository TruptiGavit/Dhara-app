import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/material.dart';

class EmptyChatState extends StatelessWidget {
  final AiModel selectedModel;
  final Function(String) onSampleQuestionTap;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onSubmitted;
  final bool? canSend;
  final VoidCallback? onSend;
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final bool isDeveloperMode;

  const EmptyChatState({
    super.key,
    required this.selectedModel,
    required this.onSampleQuestionTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.canSend,
    this.onSend,
    this.themeColors,
    this.appThemeDisplay,
    this.isDeveloperMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Welcome Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeColors?.primaryLight ?? Colors.indigo.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: themeColors?.primaryHigh ?? Colors.indigo.shade600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Welcome Title
          Text(
            'Welcome to Prashna (प्रश्न)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: themeColors?.onSurface ?? Colors.black87, // Theme-aware text color
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Welcome Subtitle
          Text(
            'Ask questions about Indic Knowledge...',
            style: TextStyle(
              fontSize: 16,
              color: themeColors?.onSurface ?? Colors.black87, // Theme-aware text color
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Search Bar in middle (only shown on empty state)
          if (controller != null)
            _buildMiddleSearchBar(),
          
          const SizedBox(height: 32),
          
          // Current Model Info - COMMENTED OUT AS REQUESTED
          /*
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.indigo.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getModelIcon(selectedModel),
                  color: Colors.indigo.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeveloperMode ? 'Current AI: ${selectedModel.displayName}' : 'AI Assistant',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: themeColors?.primaryHigh ?? Colors.indigo.shade700,
                        ),
                      ),
                      Text(
                        selectedModel.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeColors?.primary ?? Colors.indigo.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          */
          
          //const SizedBox(height: 40),
          
          // Sample Questions
         // _buildSampleQuestions(),
          
         // const SizedBox(height: 40),
          
          // Features
         // _buildFeatures(),
        ],
      ),
    );
  }

  Widget _buildMiddleSearchBar() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 56,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: themeColors?.surface ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: themeColors?.primary ?? Colors.indigo.shade400,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (themeColors?.primary ?? Colors.indigo.shade400).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: (themeColors?.onSurface ?? Colors.black).withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text Input
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmitted?.call(),
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: TextStyle(
                  color: themeColors?.onSurfaceDisable ?? Colors.grey.shade500,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: themeColors?.onSurface ?? Colors.black,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          
          // Send Button
          Padding(
            padding: const EdgeInsets.all(8),
            child: GestureDetector(
              onTap: (canSend ?? false) ? onSend : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (canSend ?? false) 
                      ? themeColors?.primaryHigh ?? Colors.indigo.shade600 
                      : themeColors?.onSurfaceDisable ?? Colors.grey.shade300,
                  shape: BoxShape.circle,
                  boxShadow: (canSend ?? false) ? [
                    BoxShadow(
                      color: (themeColors?.primary ?? Colors.indigo.shade200).withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  Icons.send,
                  color: (canSend ?? false) 
                      ? themeColors?.surface ?? Colors.white 
                      : themeColors?.onSurfaceLowest ?? Colors.grey.shade500,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 // COMMENTED OUT - Helper method for AI model icon (no longer used)
  /*
  Widget _buildSampleQuestions() {
    final questions = _getSampleQuestions(selectedModel);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try asking:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.indigo.shade700,
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...questions.map((question) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSampleQuestionCard(question),
        )),
      ],
    );
  }

  Widget _buildSampleQuestionCard(String question) {
    return GestureDetector(
      onTap: () => onSampleQuestionTap(question),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeColors?.surface ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.indigo.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.shade50,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.indigo.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.indigo.shade300,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Features:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.indigo.shade700,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildFeatureItem(
          icon: Icons.search,
          title: 'Intelligent Search',
          description: 'Find verses, definitions, and concepts across Sanskrit texts',
        ),
        
        _buildFeatureItem(
          icon: Icons.translate,
          title: 'Multi-language Support',
          description: 'Get responses in multiple scripts and languages',
        ),
        
        _buildFeatureItem(
          icon: Icons.source,
          title: 'Source Citations',
          description: 'Every answer includes proper citations and references',
        ),
        
        _buildFeatureItem(
          icon: Icons.chat_bubble_outline,
          title: 'AI-Powered Analysis',
          description: 'Deep understanding of Sanskrit grammar and context',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.indigo.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSampleQuestions(AiModel model) {
    switch (model) {
      case AiModel.gemini:
        return [
          'What is the meaning of "dharma" in the Bhagavad Gita?',
          'Find verses about compassion in ancient texts',
          'Explain the concept of karma in Sanskrit literature',
          'What are the different names of Lord Krishna?',
        ];
      case AiModel.qwen:
        return [
          'Analyze the grammatical structure of "सत्यं शिवं सुन्दरम्"',
          'Compare different interpretations of the Upanishads',
          'Find verses with specific meter patterns',
          'Explain the etymology of Sanskrit philosophical terms',
        ];
    }
  }

 
  IconData _getModelIcon(AiModel model) {
    switch (model) {
      case AiModel.gemini:
        return Icons.flash_on;
      case AiModel.qwen:
        return Icons.chat_bubble_outline;
    }
  }
  */
}

