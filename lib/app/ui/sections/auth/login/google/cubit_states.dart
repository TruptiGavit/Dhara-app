import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/ui/sections/auth/login/google/args.dart';
import 'package:dharak_flutter/app/ui/sections/auth/login/google/modal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cubit_states.g.dart';

@CopyWith()
@JsonSerializable()
class GoogleLoginCubitState {
  final String? purpose;
  final bool isInitialized;
  final int state;
  final bool isLoading;
  final bool? isInProgress;
  final String? idToken;
  final GoogleLoginArgsResult? result;

  const GoogleLoginCubitState({
    this.purpose,
    this.isInitialized = false,
    this.state = GoogleLoginModal.STATE_DEFAULT,
    this.isLoading = false,
    this.isInProgress,
    this.idToken,
    this.result,
  });

  factory GoogleLoginCubitState.fromJson(Map<String, dynamic> json) =>
      _$GoogleLoginCubitStateFromJson(json);

  Map<String, dynamic> toJson() => _$GoogleLoginCubitStateToJson(this);
}