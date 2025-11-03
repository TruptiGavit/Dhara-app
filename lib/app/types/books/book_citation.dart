import 'package:json_annotation/json_annotation.dart';

part 'book_citation.g.dart';

@JsonSerializable()
class BookChunkCitationRM {
  @JsonKey(name: 'cite_data')
  final BookCitationData citeData;

  BookChunkCitationRM({required this.citeData});

  factory BookChunkCitationRM.fromJson(Map<String, dynamic> json) =>
      _$BookChunkCitationRMFromJson(json);
  Map<String, dynamic> toJson() => _$BookChunkCitationRMToJson(this);
}

@JsonSerializable()
class BookCitationData {
  @JsonKey(name: 'Footnote')
  final String footnote;

  BookCitationData({required this.footnote});

  factory BookCitationData.fromJson(Map<String, dynamic> json) =>
      _$BookCitationDataFromJson(json);
  Map<String, dynamic> toJson() => _$BookCitationDataToJson(this);
}










