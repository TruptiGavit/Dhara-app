import 'package:json_annotation/json_annotation.dart';
import 'package:dharak_flutter/app/types/books/book_chunk.dart';

part 'book_chunk_augmentation.g.dart';

/// Response model for /bheri/chunk/auglist/{id}/ - Get all augmented chunks
@JsonSerializable()
class BookChunkAugmentationListRM {
  final List<String> augmentations;

  BookChunkAugmentationListRM({
    required this.augmentations,
  });

  factory BookChunkAugmentationListRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkAugmentationListRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunkAugmentationListRMToJson(this);
}

/// Response model for /bheri/chunk/get_aug/?text= - Get augmented chunk from text
@JsonSerializable()
class BookChunkAugmentedRM {
  final BookChunkRM data;

  BookChunkAugmentedRM({
    required this.data,
  });

  factory BookChunkAugmentedRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkAugmentedRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunkAugmentedRMToJson(this);
}

/// Response model for /bheri/chunk/get_orig/{id}/ - Get original chunk
@JsonSerializable()
class BookChunkOriginalRM {
  final BookChunkRM chunk;

  BookChunkOriginalRM({
    required this.chunk,
  });

  factory BookChunkOriginalRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkOriginalRMFromJson(json);

  Map<String, dynamic> toJson() => _$BookChunkOriginalRMToJson(this);
}

/// Source type constants for better type safety and UX
class BookChunkSourceType {
  static const String original = 'original';
  static const String mergedAugmentation = 'merged augmentation';
  static const String augmentation = 'augmentation';
  static const String none = 'none';
  
  /// Get user-friendly display name for source type
  static String getDisplayName(String? sourceType) {
    switch (sourceType) {
      case original:
        return 'Original Content';
      case mergedAugmentation:
        return 'Merged Insights';
      case augmentation:
        return 'Augmented Insight';
      case none:
        return 'Dhara Knowledge';
      default:
        return 'Content';
    }
  }
  
  /// Get color for source type (for visual hierarchy)
  static String getColorType(String? sourceType) {
    switch (sourceType) {
      case original:
        return 'blue';     // Traditional navigation
      case mergedAugmentation:
        return 'purple';   // Special insights
      case augmentation:
        return 'teal';     // Derivative content
      case none:
        return 'green';    // Dhara knowledge
      default:
        return 'red';      // Unknown - changed from grey to red
    }
  }
}



