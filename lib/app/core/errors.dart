abstract class Failure implements Exception {
  String get message;
}

class ConnectionError extends Failure {
  @override
  final String message;
  
  ConnectionError({required this.message});
}

class InvalidError extends Failure {
  @override
  final String message;
  InvalidError({required this.message});
}

class ErrorGetLoggedUser extends Failure {
  @override
  final String message;
  ErrorGetLoggedUser({required this.message});
}

class ErrorLogout extends Failure {
  @override
  final String message;
  ErrorLogout({required this.message});
}

class ErrorLoginGoogle implements Failure {
  @override
  final String message;
  ErrorLoginGoogle({required this.message});
}

class ErrorTokenEmpty implements Failure {
  @override
  final String message;
  ErrorTokenEmpty({this.message = "Token is Empty"});
}

class NotAutomaticRetrieved implements Failure {
  final String verificationId;
  @override
  final String message;
  NotAutomaticRetrieved(this.verificationId, {required this.message});
}

class InternalError implements Failure {
  @override
  final String message;
  InternalError({required this.message});
}

class RepoError implements Failure {
  static const int ERROR_TYPE_NETWORK = 1;
  static const int ERROR_TYPE_OTHER = 0;
  @override
  final String message;
  int? code;
  final int type;
  RepoError(
      {required this.message,
      this.code,
      this.type = ERROR_TYPE_NETWORK});
}

class NetworkError implements Failure {
  @override
  final String message;
  final int code;
  NetworkError({required this.message, required this.code});
}
