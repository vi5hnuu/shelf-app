part of 'shelf_bloc.dart';

@immutable
abstract class ShelfEvent {
  final CancelToken? cancelToken;
  const ShelfEvent({this.cancelToken});
}

class FetchAllMantraInfo extends ShelfEvent {
  const FetchAllMantraInfo({super.cancelToken});
}

class FetchAllMantraAudioInfo extends ShelfEvent {
  final int pageNo;
  const FetchAllMantraAudioInfo({required this.pageNo,super.cancelToken});
}

class FetchAllMantra extends ShelfEvent {
  const FetchAllMantra({CancelToken? cancelToken}) : super(cancelToken: cancelToken);
}

class FetchMantraById extends ShelfEvent {
  final String id;

  const FetchMantraById({required this.id, CancelToken? cancelToken}) : super(cancelToken: cancelToken);
}

class FetchMantraByTitle extends ShelfEvent {
  final String title;

  const FetchMantraByTitle({required this.title, CancelToken? cancelToken}) : super(cancelToken: cancelToken);
}

class FetchMantraAudioById extends ShelfEvent {
  final String id;

  const FetchMantraAudioById({required this.id, CancelToken? cancelToken}) : super(cancelToken: cancelToken);
}

class FetchMantraAudioByTitle extends ShelfEvent {
  final String title;

  const FetchMantraAudioByTitle({required this.title, CancelToken? cancelToken}) : super(cancelToken: cancelToken);
}
