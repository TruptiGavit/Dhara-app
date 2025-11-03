import 'package:dharak_flutter/app/types/verse/verse.dart';
import 'package:dharak_flutter/app/types/verse/verse_foot.dart';
import 'package:dharak_flutter/app/types/verse/verse_head.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verses.g.dart';

@JsonSerializable()
class VersesResultRM {
  VerseHeadRM? head;
  List<VerseRM> verses;
  VerseFootRM? foot;

  VersesResultRM({
    required this.head,
    required this.verses,
    required this.foot,
  });

  factory VersesResultRM.fromJson(Map<String, dynamic> json) =>
      _$VersesResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$VersesResultRMToJson(this);
}
