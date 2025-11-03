import 'package:json_annotation/json_annotation.dart';

/// Enum representing available AI models for chat interaction
enum AiModel {
  @JsonValue('gemini')
  gemini,
  
  @JsonValue('qwen')
  qwen;

  /// Display name for the AI model
  String get displayName {
    switch (this) {
      case AiModel.gemini:
        return 'Gemini 2.5 Flash';
      case AiModel.qwen:
        return 'GPT OSS';
    }
  }

  /// Description of the AI model
  String get description {
    switch (this) {
      case AiModel.gemini:
        return 'Fast and efficient';
      case AiModel.qwen:
        return 'Advanced reasoning';
    }
  }

  /// Model parameter for the unified API
  String get modelParameter {
    switch (this) {
      case AiModel.gemini:
        return 'gemini_2_5_flash';
      case AiModel.qwen:
        return 'gpt_oss_20b';
    }
  }

  /// Icon name for the model
  String get iconName {
    switch (this) {
      case AiModel.gemini:
        return 'flash_on';
      case AiModel.qwen:
        return 'psychology';
    }
  }
}

/// Configuration for AI model selection
class AiModelConfig {
  final AiModel model;
  final bool isSelected;
  final bool isAvailable;

  const AiModelConfig({
    required this.model,
    this.isSelected = false,
    this.isAvailable = true,
  });

  AiModelConfig copyWith({
    AiModel? model,
    bool? isSelected,
    bool? isAvailable,
  }) {
    return AiModelConfig(
      model: model ?? this.model,
      isSelected: isSelected ?? this.isSelected,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}




