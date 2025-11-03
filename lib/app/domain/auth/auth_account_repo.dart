import 'dart:async';
import 'dart:developer';

import 'package:dharak_flutter/app/data/local/secure/secure_local_data.dart';
import 'package:dharak_flutter/app/data/remote/api/base/dto/error_dto.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/auth/api.dart';
import 'package:dharak_flutter/app/data/remote/api/parts/auth/dto/auth_login_req_dto.dart';
import 'package:dharak_flutter/app/domain/base/domain_helper.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/providers/google/google_auth.dart';
import 'package:dharak_flutter/app/types/auth/login.dart';
import 'package:dharak_flutter/app/types/user/user.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

class AuthAccountRepository extends Disposable {
  var mLogger = Logger();

  final AuthApiRepo mAuthApiRepo;
  final SecureLocalData mSecureStorage;

  final GoogleAuthService mGoogleAuthService;

  final PublishSubject<String> _mErrorMessage = PublishSubject<String>();
  PublishSubject<String> get errorMessage => _mErrorMessage;

  final PublishSubject<bool> _mAccountStateChanged = PublishSubject<bool>();
  PublishSubject<bool> get accountChangedObservable => _mAccountStateChanged;

  final PublishSubject<bool> _mOnGoogleWebLoggedIn = PublishSubject<bool>();

  StreamSubscription<bool>? _mGoogleLoginSubscription;
  PublishSubject<bool> get onGoogleWebLoggedIn => _mOnGoogleWebLoggedIn;

  final BehaviorSubject<UserRM?> _mSubjectAccountUser = BehaviorSubject.seeded(
    null,
  );

  UserRM? _mUser;
  BehaviorSubject<UserRM?> get mAccountUserObservable => _mSubjectAccountUser;

  AuthAccountRepository({
    required this.mAuthApiRepo,
    required this.mSecureStorage,
    required this.mGoogleAuthService,
  });

  @override
  void dispose() {
    _mErrorMessage.close();
    _mOnGoogleWebLoggedIn.close();
    _mSubjectAccountUser.close();
    _mAccountStateChanged.close();
    try {
      _mGoogleLoginSubscription?.cancel();
      _mGoogleLoginSubscription = null;
    } catch (e) {
      print("AuthAccountRepository dispose error: ");
      print(e);
    }
  }

  initSetup() {
    mGoogleAuthService.initGoogleClient();
    _mGoogleLoginSubscription = mGoogleAuthService.onLoggedIn.listen((onData) {
      _mOnGoogleWebLoggedIn.sink.add(onData);
    });
    _loadUser();
  }

  Future<UserRM?> _loadUser() async {
    var name = await mSecureStorage.getDisplayName();
    var email = await mSecureStorage.getEmail();
    var picture = await mSecureStorage.getPicture();

    if (name.isNotEmpty || email != null || picture != null) {
      _mUser = UserRM(name: name, email: email, picture: picture);
      _mSubjectAccountUser.sink.add(_mUser);
    }
    return _mUser;
  }

  Future<DomainResult<bool>> login({String? googleIdToken}) async {
    var result =
        await domainCallBeforeSave<bool, AuthLoginRM, ErrorDto, UserRM>(
          networkCall: () async {
            print("auth_repo login 0:");

            // Detect token type: JWT (ID token) has 2 dots, OAuth access token doesn't
            bool isJWT = googleIdToken?.contains('.') == true && 
                         googleIdToken!.split('.').length == 3;
            
            String? accessToken;
            String? idToken;
            
            if (isJWT) {
              // Mobile sends ID token
              idToken = googleIdToken;
              print("auth_repo: Sending ID token (mobile)");
            } else {
              // Web sends access token
              accessToken = googleIdToken;
              print("auth_repo: Sending access token (web)");
            }

            return await mAuthApiRepo.login(
              AuthLoginReqDto(
                accessToken: accessToken,
                idToken: idToken,
                client: kIsWeb ? 'web_client' : 'bheri_web',
              ),
            );
          },
          saveCallResult: (remoteData) async {
            await mSecureStorage.saveAccessToken(remoteData.accessToken);
            await mSecureStorage.saveRefreshToken(remoteData.refreshToken);
            await mSecureStorage.saveEmail(remoteData.user?.email);
            await mSecureStorage.saveDisplayName(remoteData.user?.getName());
            await mSecureStorage.savePicture(remoteData.user?.picture);

            await _loadUser();

            return Future.value(_mUser);
          },
          finalResult: (savedData) => savedData != null,
        );

    if (result.status == DomainResultStatus.SUCCESS && result.data != null) {
      _mAccountStateChanged.sink.add(result.data!);
    }
    return result;
  }

  /* *****************************************************************************
   *                              Google
   */

  Future<GoogleSignInAuthentication> signInWithGoogle() async {
    try {
      var cred = await mGoogleAuthService.signInWithGoogle();
      return cred;
    } catch (e) {
      inspect(e);
      print(e);
      throw e;
    }
  }

  /* ****************************************************************8*
   *                                Google ID Token Methods
   */

  Future<String> getIdToken() async {
    var idTOken = await mGoogleAuthService.getIdToken();
    int tokenLength = idTOken.length;
    int tokenL2 = (tokenLength / 2).ceil();
    print("getIdToken: token obtained");

    debugPrint(idTOken.substring(0, tokenL2));
    debugPrint(idTOken.substring(tokenL2, tokenLength));
    return idTOken;
  }

  Future<String> getIdTokenWithAccountPicker() async {
    // Force account picker and get new token
    var idTOken = await mGoogleAuthService.getIdTokenWithAccountPicker();
    int tokenLength = idTOken.length;
    int tokenL2 = (tokenLength / 2).ceil();
    print("getIdTokenWithAccountPicker: token obtained");

    debugPrint(idTOken.substring(0, tokenL2));
    debugPrint(idTOken.substring(tokenL2, tokenLength));
    return idTOken;
  }

  Future<String> getIdTokenSilent() async {
    // Try silent sign-in with current Google user
    var idTOken = await mGoogleAuthService.getIdTokenSilent();
    int tokenLength = idTOken.length;
    int tokenL2 = (tokenLength / 2).ceil();
    print("getIdTokenSilent: token obtained");

    debugPrint(idTOken.substring(0, tokenL2));
    debugPrint(idTOken.substring(tokenL2, tokenLength));
    return idTOken;
  }

  switchAccount() async {
    // Clear only the authentication tokens, not the display info (email, name, picture)
    // DON'T logout from Google to allow silent sign-in with last account
    await mSecureStorage.saveAccessToken(null); // This will delete the token
    await mSecureStorage.saveRefreshToken(null); // This will delete the token
    
    _mAccountStateChanged.sink.add(false);
    _mSubjectAccountUser.sink.add(null);
  }

  logout() async {
    await mSecureStorage.clear();
    await mGoogleAuthService.logout(); // Also logout from Google
    _mAccountStateChanged.sink.add(false);
    _mSubjectAccountUser.sink.add(null);
  }
}