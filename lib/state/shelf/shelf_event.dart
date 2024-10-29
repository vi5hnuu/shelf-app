part of 'shelf_bloc.dart';

@immutable
abstract class ShelfEvent {
  const ShelfEvent();
}

class FetchItemsInShelf extends ShelfEvent{
  final String? shelfId;
  final int pageNo;
  const FetchItemsInShelf({required this.shelfId,required this.pageNo});
}

class MoveItemsTo extends ShelfEvent{
  final String? toShelfId;
  final List<String> fileIds;
  final List<String> shelfIds;

  const MoveItemsTo({
      required this.toShelfId,
      required this.fileIds,
      required this.shelfIds});
}

class DeleteItems extends ShelfEvent{
  final bool permanentDelete;
  final List<String> fileIds;
  final List<String> shelfIds;

  const DeleteItems({
      required this.fileIds,
      required this.shelfIds,
      required this.permanentDelete});
}
