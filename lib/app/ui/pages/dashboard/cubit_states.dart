
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:dharak_flutter/app/bloc/state_bloc.dart';
import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:dharak_flutter/app/types/verse/language_pref.dart';
import 'package:dharak_flutter/app/ui/pages/dashboard/dashboard_args.dart';

part 'cubit_states.g.dart';

@CopyWith()
class DashboardCubitState extends BlocState {
  // final CommuneBankerBox? myCommuneBanker;

  final bool? isLoading;

  final bool? isInitialized;

  final DashboardArgsResult? result;

  final bool? isEmpty;
  final int? retryCounter;
  final int? toastCounter;
  final int loginNeededCounter;
  final int googleWebLoggedInCounter;
  final String? message;
  final String? currentTab;

  final VersesLanguagePrefRM? verseLanguagePref;

  final UserRM? user;

  final bool authPopupOpen;

  DashboardCubitState({
    // this.myCommuneBanker,
    this.isLoading,
    this.isInitialized,
    this.result,
    this.retryCounter,
    this.toastCounter,
    this.loginNeededCounter =  0,
    this.googleWebLoggedInCounter = 0,
    this.isEmpty,
    this.message,
    this.currentTab,
    this.user,
    this.verseLanguagePref,
    this.authPopupOpen = false
  });

  @override
  List<Object?> get props => [
        isLoading,
        isInitialized,
        retryCounter,
        toastCounter,
        isEmpty,
        loginNeededCounter,
        googleWebLoggedInCounter,
        // myCommuneBanker,
        result,
        currentTab,
        user,
        verseLanguagePref,
        authPopupOpen
      ];
}
