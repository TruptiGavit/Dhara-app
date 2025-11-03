
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'language_pref.g.dart';

@JsonSerializable()
class VersesLanguagePrefRM extends Equatable {
  final String? input;
  final String? output;

  const VersesLanguagePrefRM({
     this.input,
     this.output
  });

  factory VersesLanguagePrefRM.fromJson(Map<String, dynamic> json) =>
      _$VersesLanguagePrefRMFromJson(json);
  Map<String, dynamic> toJson() => _$VersesLanguagePrefRMToJson(this);

  @override
  List<Object?> get props => [input, output];
}
