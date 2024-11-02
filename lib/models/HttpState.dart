class HttpState{
  final bool loading;
  final String? error;
  final bool? done;

  const HttpState({this.loading=false,this.error,this.done});
  const HttpState.loading():this(loading: true);
  const HttpState.error({required String? error}):this(loading: false,error: error);
  const HttpState.done():this(loading: false,done: true);
}