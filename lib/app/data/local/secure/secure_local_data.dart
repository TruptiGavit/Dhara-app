import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureLocalData {
  static const String ACCESS_TOKEN = "accessToken";
  static const String REFRESH_TOKEN = "refreshToken";

  static const String EMAIL = "email";
  static const String PICTURE = "picture";

  // static const String IS_LOGGED_IN = "LOGGED_IN";

  static const String DISPLAY_NAME = "DISPLAY_NAME";

  static final SecureLocalData _singleton = SecureLocalData._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory SecureLocalData() {
    return _singleton;
  }

  SecureLocalData._internal();
  // {
  //   print("print: ");
  //   _storage = FlutterSecureStorage();

  // }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: ACCESS_TOKEN);
  }

  Future<void> saveAccessToken(String? accessToken) async {
    if (accessToken == null) {
      _storage.delete(key: ACCESS_TOKEN);
    }
    return await _storage.write(key: ACCESS_TOKEN, value: accessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: REFRESH_TOKEN);
  }

  Future<void> saveRefreshToken(String? refreshToken) async {
    if (refreshToken == null) {
      _storage.delete(key: REFRESH_TOKEN);
    }
    return await _storage.write(key: REFRESH_TOKEN, value: refreshToken);
  }

  Future<String?> getEmail() async {
    return (await _storage.read(key: EMAIL)) ;//?? "navneet.kunal1988@gmail.com";
  }

  Future<void> saveEmail(String? email) async {
    if (email == null) {
      _storage.delete(key: EMAIL);
    }
    return await _storage.write(key: EMAIL, value: email);
  }


  Future<String> getDisplayName() async {
    return (await _storage.read(key: DISPLAY_NAME)) ?? "";
  }

  Future<void> saveDisplayName(String? displayName) async {
    if (displayName == null) {
      _storage.delete(key: DISPLAY_NAME);
    }
    return await _storage.write(key: DISPLAY_NAME, value: displayName);
  }

  Future<String?> getPicture() async {
    return (await _storage.read(key: PICTURE));
  }

  Future<void> savePicture(String? picture) async {
    if (picture == null) {
      _storage.delete(key: PICTURE);
    }
    return await _storage.write(key: PICTURE, value: picture);
  }

  Future<void> clear() async {
    return await _storage.deleteAll();
  }
}
