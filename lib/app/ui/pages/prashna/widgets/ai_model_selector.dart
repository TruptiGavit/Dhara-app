import 'package:dharak_flutter/app/types/prashna/ai_model.dart';
import 'package:dharak_flutter/res/theme/app_theme_colors.dart';
import 'package:dharak_flutter/res/theme/app_theme_display.dart';
import 'package:flutter/material.dart';

class AiModelSelector extends StatelessWidget {
  final AiModel selectedModel;
  final Function(AiModel) onModelSelected;
  final VoidCallback onClose;
  final AppThemeColors? themeColors;
  final AppThemeDisplay? appThemeDisplay;
  final bool isDeveloperMode;

  const AiModelSelector({
    super.key,
    required this.selectedModel,
    required this.onModelSelected,
    required this.onClose,
    this.themeColors,
    this.appThemeDisplay,
    this.isDeveloperMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors?.primaryLight ?? Colors.indigo.shade50,
        border: Border(
          bottom: BorderSide(
            color: themeColors?.primaryLight ?? Colors.indigo.shade100,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: themeColors?.primaryHigh ?? Colors.indigo.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Choose AI Model',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeColors?.primaryHigh ?? Colors.indigo.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    color: themeColors?.primaryHigh ?? Colors.indigo.shade700,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          // Model Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _getAvailableModels().map((model) {
                final isSelected = model == selectedModel;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildModelCard(
                      model: model,
                      isSelected: isSelected,
                      onTap: () => onModelSelected(model),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModelCard({
    required AiModel model,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeColors?.primaryHigh ?? Colors.indigo.shade600 
              : themeColors?.surface ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? themeColors?.primaryHigh ?? Colors.indigo.shade600 
                : themeColors?.primaryLight ?? Colors.indigo.shade200,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: (themeColors?.primary ?? Colors.indigo.shade200).withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Model Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (themeColors?.surface ?? Colors.white).withOpacity(0.2) 
                    : themeColors?.primaryLight ?? Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getModelIcon(model),
                size: 24,
                color: isSelected 
                    ? themeColors?.surface ?? Colors.white 
                    : themeColors?.primaryHigh ?? Colors.indigo.shade700,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Model Name
            Text(
              model.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? themeColors?.surface ?? Colors.white 
                    : themeColors?.primaryHigh ?? Colors.indigo.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // Model Description
            Text(
              model.description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected 
                    ? (themeColors?.surface ?? Colors.white).withOpacity(0.8) 
                    : themeColors?.primary ?? Colors.indigo.shade500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Selection Indicator
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (themeColors?.surface ?? Colors.white).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: themeColors?.surface ?? Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get available models based on developer mode
  List<AiModel> _getAvailableModels() {
    if (isDeveloperMode) {
      // Developer mode: show all models
      return AiModel.values;
    } else {
      // Normal users: only show GPT OSS (qwen)
      return [AiModel.qwen];
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
}

