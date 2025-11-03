
class ApiResponse<Type, ErrorType> {
  final Type? data;
  final ErrorType? error;
  final String? message;
  final int? dioStatusCode;

  final ApiResponseStatus status;

  ApiResponse(
    this.status, {
    this.data,
    this.error,
    this.message,
    this.dioStatusCode
  });

  factory ApiResponse.success({
    required Type data,
  }) = _ApiResponseSuccess;

  factory ApiResponse.error({Type? data, ErrorType? error, String? message, int? dioStatusCode}) = _ApiResponseError;

  //fun <T, E> loading(data: T? = null): ApiResponse<T, E> {
        //     return ApiResponse(Status.LOADING, data, null, null);
        // }

}

enum ApiResponseStatus {
  SUCCESS,
  ERROR,
  /** not in use */
  LOADING
}

class _ApiResponseSuccess<Type, ErrorType>
    extends ApiResponse<Type, ErrorType> {
  _ApiResponseSuccess({required Type data})
      : super(ApiResponseStatus.SUCCESS, data: data);
}

class _ApiResponseError<Type, ErrorType> extends ApiResponse<Type, ErrorType> {
  _ApiResponseError({Type? data, ErrorType? error, String? message, int? dioStatusCode})
      : super(ApiResponseStatus.ERROR, data: data, error: error, message: message, dioStatusCode: dioStatusCode);
}
