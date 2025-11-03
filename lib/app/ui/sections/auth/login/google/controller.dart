import 'package:dharak_flutter/app/domain/auth/auth_account_repo.dart';
import 'package:dharak_flutter/app/ui/constants.dart';
import 'package:dharak_flutter/app/ui/sections/auth/constants.dart';
import 'package:dharak_flutter/app/ui/sections/auth/login/google/args.dart';
import 'package:dharak_flutter/app/ui/sections/auth/login/google/cubit_states.dart';
import 'package:dharak_flutter/app/ui/sections/auth/login/google/modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoogleLoginController extends Cubit<GoogleLoginCubitState> {
  final AuthAccountRepository mAuthAccountRepository;

  GoogleLoginController({required this.mAuthAccountRepository})
    : super(GoogleLoginCubitState(state: GoogleLoginModal.STATE_DEFAULT));

  @override
  void dispose() {
    // Clean up any resources if needed
  }

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> initData(GoogleLoginArgsRequest args) async {
    var purpose = args.purpose;
    var uiState = state.state;

    emit(
      state.copyWith(
        purpose: purpose,
        isInitialized: true,
        state: uiState,
        isLoading: false,
      ),
    );

    if (purpose == AuthUiConstants.PURPOSE_GOOGLE_LOGIN_DIRECT) {
      onSubmit();
    } else if (purpose == AuthUiConstants.PURPOSE_GOOGLE_AFTER_LOGIN) {
      print("afterGoogleUILogin init");
      afterGoogleUILogin().then((onValue) {});
    }
  }

  void setModalState(int stateModal) {
    if (state.state == stateModal) {
      return;
    }

    emit(state.copyWith(state: stateModal));
  }

  int getModalState() {
    return state.state;
  }

  void end() {
    emit(
      state.copyWith(
        result: GoogleLoginArgsResult(
          resultCode: "RESULT_CANCELED",
        ),
      ),
    );
  }

  onSubmit() {
    Future.delayed(Duration(milliseconds: 100), () async {
      await directLogin();

      if (state.idToken != null) {
        print("google login onSubmit: success");
        onSuccess();
      } else {
        print("google login onSubmit: failed");
        onFailed("unable to google login");
      }
    });
  }

  onSubmitWithAccountPicker() {
    Future.delayed(Duration(milliseconds: 100), () async {
      await _getGoogleIdTokenWithAccountPicker();

      if (state.idToken != null) {
        print("google login onSubmitWithAccountPicker: success");
        onSuccess();
      } else {
        print("google login onSubmitWithAccountPicker: failed - no token");
        onFailed("unable to login with selected account");
      }
    });
  }

  onSubmitSilent() {
    Future.delayed(Duration(milliseconds: 100), () async {
      await _getGoogleIdTokenSilent();

      if (state.idToken != null) {
        print("google login onSubmitSilent: success");
        onSuccess();
      } else {
        print("google login onSubmitSilent: failed - no token");
        onFailed("unable to silent login");
      }
    });
  }

  Future<void> _getGoogleIdToken() async {
    print("google login ctrl _getGoogleIdToken: idtoken");
    try {
      var token = await mAuthAccountRepository.getIdToken();
      print("_getGoogleIdToken: idtoken obtained");
      emit(state.copyWith(idToken: token));
    } catch (e) {
      print("_getGoogleIdToken error: $e");
    }
  }

  Future<void> _getGoogleIdTokenWithAccountPicker() async {
    print("google login ctrl _getGoogleIdTokenWithAccountPicker: idtoken");
    try {
      var token = await mAuthAccountRepository.getIdTokenWithAccountPicker();
      print("_getGoogleIdTokenWithAccountPicker: idtoken obtained");
      emit(state.copyWith(idToken: token));
    } catch (e) {
      print("_getGoogleIdTokenWithAccountPicker error: $e");
    }
  }

  Future<void> _getGoogleIdTokenSilent() async {
    print("google login ctrl _getGoogleIdTokenSilent: idtoken");
    try {
      var token = await mAuthAccountRepository.getIdTokenSilent();
      print("_getGoogleIdTokenSilent: idtoken obtained");
      emit(state.copyWith(idToken: token));
    } catch (e) {
      print("_getGoogleIdTokenSilent error: $e");
    }
  }

  Future<bool> afterGoogleUILogin() async {
    try {
      emit(state.copyWith(idToken: null));
      print("afterGoogleUILogin login: 1");
      await _getGoogleIdToken();

      if (state.idToken != null) {
        print("afterGoogleUILogin login onSubmit: 1");
        onSuccess();
      } else {
        print("afterGoogleUILogin login onSubmit: 2");
        onFailed("unable to google login");
      }

      return true;
    } catch (e) {
      print("afterGoogleUILogin error: $e");
      return false;
    }
  }

  Future<bool> directLogin() async {
    print("directLogin login: 1");

    try {
      emit(state.copyWith(idToken: null));
      var result = await mAuthAccountRepository.signInWithGoogle();

      print("directLogin login: 2");
      await _getGoogleIdToken();

      return true;
    } catch (e) {
      print("directLogin error: $e");
      return false;
    }
  }

  /* *********************************************************************************************************
| *                                            response Args
| */

  void onSuccess() {
    print("google login onSuccess: ");
    emit(
      state.copyWith(
        result: GoogleLoginArgsResult(
          resultCode: "RESULT_SUCCESS",
          idToken: state.idToken,
        ),
      ),
    );
  }

  void onFailed(String message) {
    setModalState(GoogleLoginModal.STATE_DEFAULT);

    emit(
      state.copyWith(
        result: GoogleLoginArgsResult(
          resultCode: "RESULT_FAILED",
        ),
      ),
    );
  }
}