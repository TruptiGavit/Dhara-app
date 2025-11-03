import 'package:dharak_flutter/app/domain/base/error_type.dart';
import 'package:json_annotation/json_annotation.dart';
// import 'package:json_serializable/json_serializable.dart';

part 'error_dto.g.dart';

@JsonSerializable()
class ErrorDto with ErrorType {
  // final int? code;
  final int? httpCode;
  
  final int? statusCode;

  final String? error;
  final bool? success;

  final String? message;

  

  ErrorDto({
    this.httpCode =  500,
    int? statusCode,
    String? error,
    this.success = false,
    String? message,
  }) : this.statusCode = statusCode ?? 500,
       this.error = error ?? "",
       this.message = message ?? "";

  factory ErrorDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorDtoToJson(this);

  @override
  String? getMessage() {
    return message;
  }
}
