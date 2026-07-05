import 'package:PiliPlus/http/loading_state.dart';

typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(dynamic value) {
  if (value is JsonMap) {
    return value;
  }
  return Map<String, dynamic>.from(value as Map);
}

bool responseCodeSuccess(JsonMap body) => body['code'] == 0;

String? responseMessage(JsonMap body) => body['message']?.toString();

LoadingState<T> loadingStateFromJsonData<T>(
  JsonMap body, {
  required T Function(dynamic data) parser,
  String? Function(JsonMap body)? errorMessage,
}) {
  if (responseCodeSuccess(body)) {
    return Success(parser(body['data']));
  }
  return Error(errorMessage?.call(body) ?? responseMessage(body));
}

LoadingState<T> loadingStateFromJsonBody<T>(
  JsonMap body, {
  required T Function(JsonMap body) parser,
  String? Function(JsonMap body)? errorMessage,
}) {
  if (responseCodeSuccess(body)) {
    return Success(parser(body));
  }
  return Error(errorMessage?.call(body) ?? responseMessage(body));
}

Map<String, dynamic> statusSuccess<T>({
  T? data,
  String? msg,
  Map<String, dynamic>? extra,
}) {
  final result = <String, dynamic>{'status': true};
  if (data != null) {
    result['data'] = data;
  }
  if (msg != null) {
    result['msg'] = msg;
  }
  if (extra != null) {
    result.addAll(extra);
  }
  return result;
}

Map<String, dynamic> statusFailure({
  Object? msg,
  Map<String, dynamic>? extra,
}) {
  final result = <String, dynamic>{
    'status': false,
    'msg': msg?.toString(),
  };
  if (extra != null) {
    result.addAll(extra);
  }
  return result;
}

Map<String, dynamic> statusResultFromJsonData<T>(
  JsonMap body, {
  T Function(dynamic data)? parser,
  String? Function(JsonMap body)? successMessage,
  String? Function(JsonMap body)? errorMessage,
  Map<String, dynamic>? Function(JsonMap body)? successExtra,
  Map<String, dynamic>? Function(JsonMap body)? errorExtra,
}) {
  if (responseCodeSuccess(body)) {
    return statusSuccess<T>(
      data: parser == null ? null : parser(body['data']),
      msg: successMessage?.call(body),
      extra: successExtra?.call(body),
    );
  }
  return statusFailure(
    msg: errorMessage?.call(body) ?? responseMessage(body),
    extra: errorExtra?.call(body),
  );
}

Map<String, dynamic> statusResultFromJsonBody<T>(
  JsonMap body, {
  T Function(JsonMap body)? parser,
  String? Function(JsonMap body)? successMessage,
  String? Function(JsonMap body)? errorMessage,
  Map<String, dynamic>? Function(JsonMap body)? successExtra,
  Map<String, dynamic>? Function(JsonMap body)? errorExtra,
}) {
  if (responseCodeSuccess(body)) {
    return statusSuccess<T>(
      data: parser == null ? null : parser(body),
      msg: successMessage?.call(body),
      extra: successExtra?.call(body),
    );
  }
  return statusFailure(
    msg: errorMessage?.call(body) ?? responseMessage(body),
    extra: errorExtra?.call(body),
  );
}
