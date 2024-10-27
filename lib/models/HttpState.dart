class ErrorModel{
  final String message;
  final int? statusCode;

  ErrorModel({required this.message,this.statusCode});
}

class HttpState{
  final bool loading;
  final ErrorModel? error;

  const HttpState({this.loading=false,this.error});
  const HttpState.loading():this(loading: true);
  const HttpState.error({required ErrorModel? error}):this(loading: false,error: error);
}