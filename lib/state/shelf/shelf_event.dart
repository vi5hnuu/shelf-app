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

class CreateShelfIn extends ShelfEvent{
  final String? shelfId;

  const CreateShelfIn({this.shelfId});
}

class CreateFileItem{
  final PlatformFile file;
  final List<String> tags;

  const CreateFileItem({
    required this.file,
    this.tags = const []});
}

class SaveFilesInShelf extends ShelfEvent{
  final String? shelfId;
  final List<CreateFileItem> files;
  const SaveFilesInShelf({required this.shelfId,required this.files});
}

class MoveItemsTo extends ShelfEvent{
  final String? toShelfId;
  final String parentShelfId;//the shelf in which fileIds and shelfIds exists
  final List<String> fileIds;
  final List<String> shelfIds;

  const MoveItemsTo({
      required this.toShelfId,
      required this.parentShelfId,
      required this.fileIds,
      required this.shelfIds});
}

class DeleteItems extends ShelfEvent{
  final bool permanentDelete;
  final String parentShelfId;//the shelf on which fileIds/shelfIds exists
  final List<String> fileIds;
  final List<String> shelfIds;

  const DeleteItems({
      required this.parentShelfId,
      required this.fileIds,
      required this.shelfIds,
      this.permanentDelete=false});
}
