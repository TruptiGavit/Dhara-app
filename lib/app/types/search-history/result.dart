import 'package:json_annotation/json_annotation.dart';

part 'result.g.dart';

@JsonSerializable()
class SearchHistoryResultRM {
  bool? success;
  List<String> history;
  String? message;

  SearchHistoryResultRM({
    required this.success,
    required this.history,
    required this.message,
  });

  factory SearchHistoryResultRM.fromJson(Map<String, dynamic> json) =>
      _$SearchHistoryResultRMFromJson(json);
  Map<String, dynamic> toJson() => _$SearchHistoryResultRMToJson(this);
}
