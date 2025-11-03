// import 'package:common/bloc/state_bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';

part 'cubit_states.g.dart';

@CopyWith()
class LabsCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  static const PAGE_STATE_DEFAULT = 0;
  static const PAGE_STATE_SENT = 1;

  final bool? isLoading;

  final bool? isInitialized;

  final bool? isEmpty;

  final String? message;

  final int pageState;


  final String? idToken;


  // final int state;
  // final int purpose;

  // final bool  isAuthorized;
// val state: Int = AuthUiConstants.STATE_DEFAULT,
  LabsCubitState({
    // this.myCommuneBanker,
    this.isLoading,
    this.isInitialized,
    this.isEmpty,
    this.message,
     this.pageState = PAGE_STATE_DEFAULT,
    this.idToken,
    // required this.state ,
    // required this.purpose,
    // this.isAuthorized = false
  });

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        isEmpty,
        pageState,
        idToken,
        // state,
        // purpose,
        // isAuthorized
      ];
}
