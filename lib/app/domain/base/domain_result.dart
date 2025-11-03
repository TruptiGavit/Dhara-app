class DomainResult<Type> {
  static const int ERROR_TYPE_NETWORK = 1;
  static const int ERROR_TYPE_OTHER = 0;

  final Type? data;
  final int? errorType;
  final int? errorCode;

  final String? message;

  final DomainResultStatus status;

  DomainResult(this.status,
      {this.data, this.errorType, this.errorCode, this.message});

  factory DomainResult.success({
    required Type data,
  }) = _DomainResultSuccess;

  factory DomainResult.error(
      {Type? data,
      int errorType,
      int? errorCode,
      String? message}) = _DomainResultFailure;

  //fun <T, E> loading(data: T? = null): DomainResult<T, E> {
  //     return DomainResult(Status.LOADING, data, null, null);
  // }
}

enum DomainResultStatus {
  SUCCESS,
  ERROR,
  /** not in use */
  // LOADING
}

// DomainResult {
//   SUCCESS,
//   ERROR,
//   /** not in use */
//   // LOADING
// }

class _DomainResultSuccess<Type> extends DomainResult<Type> {
  _DomainResultSuccess({required Type data})
      : super(DomainResultStatus.SUCCESS, data: data);
}

class _DomainResultFailure<Type> extends DomainResult<Type> {
  _DomainResultFailure(
      {Type? data, int? errorType, int? errorCode, String? message})
      : super(DomainResultStatus.ERROR,
            data: data,
            errorType: errorType,
            errorCode: errorCode,
            message: message);
}
