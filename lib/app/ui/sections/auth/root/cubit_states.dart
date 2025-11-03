
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/ui/sections/auth/root/arg.dart';

part 'cubit_states.g.dart';

@CopyWith()
class AuthRootCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  final bool? isLoading;

  final bool? isInitialized;

  final AuthRootArgsResult? result;

  final bool? isEmpty;
  final int? retryCounter;
  final int? toastCounter;
  final String? message;

  // final String? formEmail;

  // final bool? formIsSubmitValid;
  final int state;
  final int purpose;

  // final bool isDefaultLoginOpen ;

  final bool  isAuthorized;
// val state: Int = AuthUiConstants.STATE_DEFAULT,
  AuthRootCubitState(
      {
      // this.myCommuneBanker,
      this.isLoading,
      this.isInitialized,
      this.result,
      this.retryCounter,
      this.toastCounter,
      this.isEmpty,
      this.message,
      // this.formEmail,
      // this.formIsSubmitValid,
      required this.state ,
      required this.purpose,
      this.isAuthorized = false,
      // this.isDefaultLoginOpen = false
      
      });

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        retryCounter,
        toastCounter,
        isEmpty,
        // myCommuneBanker,
        // formEmail,
        // formIsSubmitValid,
        result,
        state,
        purpose,
        isAuthorized,
        // isDefaultLoginOpen
      ];
}
