part of 'shelf_bloc.dart';

@immutable
abstract class ShelfEvent {
  const ShelfEvent();
}

class FetchNextItemsInShelf extends ShelfEvent{
  final String? shelfId;
  const FetchNextItemsInShelf({required this.shelfId});
}

class CreateShelfIn extends ShelfEvent{
  final String? shelfId;
  final String title;
  final String? description;
  final String? coverImage;
  final List<String>? tags;

  const CreateShelfIn({this.shelfId,required this.title,this.description='',this.coverImage,this.tags=const []});
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
  final String parentShelfId;//the shelf on which fileIds/shelfIds exists
  final List<String> fileIds;
  final List<String> shelfIds;

  const DeleteItems({
      required this.parentShelfId,
      required this.fileIds,
      required this.shelfIds});
}
