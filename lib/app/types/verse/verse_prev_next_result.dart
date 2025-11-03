import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verse_prev_next_result.g.dart';

// Response model for both previous and next verse API calls
// Maps the API response structure with success, message, and verse data
@JsonSerializable()
class VersePrevNextResultRM {
  final bool? success;
  final String message;
  
  // The previous/next verse data - can be null if no verse available
  @JsonKey(name: 'prev_sib')
  final VerseRM? prevSib;
  
  @JsonKey(name: 'next_sib') 
  final VerseRM? nextSib;

  VersePrevNextResultRM({
    this.success,
    required this.message,
    this.prevSib,
    this.nextSib,
  });

  factory VersePrevNextResultRM.fromJson(Map<String, dynamic> json) =>
      _$VersePrevNextResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$VersePrevNextResultRMToJson(this);

  // Helper method to get the actual verse data (either prev or next)
  VerseRM? getVerseData() {
    return prevSib ?? nextSib;
  }
} 