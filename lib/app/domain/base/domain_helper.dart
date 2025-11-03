import 'package:dharak_flutter/app/core/errors.dart';
import 'package:dharak_flutter/app/domain/base/domain_result.dart';
import 'package:dharak_flutter/app/data/remote/api/base/api_response.dart';
import 'package:dharak_flutter/app/domain/base/error_type.dart';

Future<DomainResult<T>> domainGetSynced<T, NetType, NetErrType>({
  required T Function(NetType? remoteData) obQuery,
  Future<ApiResponse<NetType, NetErrType>> Function()? networkCall,
  Future<void> Function(NetType remoteData)? saveCallResult,
  //  syncConfig: DataSyncConfig? = DataSyncConfig.with(),
}) async {
  // val shouldSync = mObRepoSynced.canSync(
  //       syncConfig?.period ?: StoreConstants.Synced.PERIOD_DEFAULT,
  //       syncConfig?.syncType,
  //       syncConfig?.key
  //   )

  bool shouldSync = true;

  NetType? remoteData;
  if (shouldSync) {
    //            info { "operationGetSynced $shouldSync" }
    var responseStatus = await networkCall?.call();
    if (responseStatus?.status == ApiResponseStatus.SUCCESS &&
        saveCallResult != null) {
      saveCallResult.call(responseStatus!.data!);

      remoteData = responseStatus.data;
      // syncConfig?.syncType?.let {
      //     mObRepoSynced.setSynced(it, syncConfig.key, syncConfig.detail)
      // }
    } else if (responseStatus?.status == ApiResponseStatus.ERROR) {
      return DomainResult.error(
        errorType:
            responseStatus?.error != null
                ? DomainResult.ERROR_TYPE_NETWORK
                : DomainResult.ERROR_TYPE_OTHER,
        message: responseStatus?.message,
      );
    }
  }

  try {
    var source = obQuery.call(remoteData);
    return DomainResult.success(data: source);
  } on RepoError catch (e) {
    return DomainResult.error(
      errorType: DomainResult.ERROR_TYPE_OTHER,
      message: e.message,
    );
  }

  //        info{"obquery: $source"}
}

Future<DomainResult<T>>
domainCallBeforeSave<T, NetType, NetErrType extends ErrorType, SaveType>({
  Future<ApiResponse<NetType, NetErrType>> Function()? networkCall,
  Future<SaveType>? Function(NetType remoteData)? saveCallResult,
  required T? Function(SaveType? savedData) finalResult,
}) async {
  // ignore: unused_local_variable
  var responseStatus = await networkCall?.call();
  SaveType? saveRes;

  if (responseStatus?.status == ApiResponseStatus.SUCCESS &&
      saveCallResult != null) {
    saveRes = await saveCallResult.call(responseStatus!.data!);
  } else if (responseStatus?.status == ApiResponseStatus.ERROR) {
    return DomainResult.error(
      errorType:
          responseStatus?.error != null
              ? DomainResult.ERROR_TYPE_NETWORK
              : DomainResult.ERROR_TYPE_OTHER,
      message: responseStatus?.error?.getMessage() ?? responseStatus?.message,
    );
  }

  var result = finalResult.call(saveRes);
  if (result != null) {
    return DomainResult.success(data: result);
  }
  return DomainResult.error(message: "something went wrong 3");
}
