part of 'shelf_bloc.dart';

@immutable
class ShelfState extends Equatable with WithHttpState {
  static const String ROOT_SHELF_ID="0";
  final Set<String?> _invalidatedShelfs;//NULL -> root, shelfId -> shelf
  final Shelf _shelf;

  ShelfState({
    Shelf? shelf,
    Set<String?> invalidatedShelfs=const {},
    Map<String,HttpState>? httpStates,
  }) : _shelf = shelf ?? Shelf.rootShelf(rootShelfId: ROOT_SHELF_ID),_invalidatedShelfs=invalidatedShelfs{
    this.httpStates.addAll(httpStates ?? {});
  }

  ShelfState copyWith({
    Map<String, HttpState>? httpStates,
    Shelf? shelf,
    Set<String?>? invalidatedShelfs=const {},
  }) {
    return ShelfState(
      invalidatedShelfs: invalidatedShelfs ?? _invalidatedShelfs,
      httpStates: httpStates ?? this.httpStates,
      shelf: shelf ?? _shelf
    );
  }

  factory ShelfState.initial() => ShelfState();

  Shelf get shelf{
    return _shelf;
  }

  Shelf clearShelf({required String? shelfId}){
    if(shelfId==null) return Shelf.rootShelf(rootShelfId: ROOT_SHELF_ID);

    final reqShelf=_shelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelfId");
    return reqShelf
      ..files.clear()
      ..shelfs.clear();
  }

  isShelfInvalid(String? shelfId){
    return _invalidatedShelfs.contains(shelfId);
  }

  hasPage({String? shelfId,required int pageNo}){
    final Shelf? reqShelf= shelfId==null ? _shelf :  _shelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelf id");
    return (reqShelf.shelfs.length+reqShelf.files.length)/Constants.DEFAULT_PAGE_SIZE>=pageNo;
  }

  canLoadPage({String? shelfId,required int pageNo}){
    var invalidShelf=_invalidatedShelfs.contains(shelfId);
    if((invalidShelf && pageNo!=1) || isLoading(forr: Httpstates.ITEMS_IN_SHELF)) return false;

    final Shelf? reqShelf= shelfId==null ? _shelf :  _shelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelf id");
    if(pageNo!=1 && reqShelf.totalPages==null) throw Exception("Total pages not initialized");

    /*
    if loaded pages is not perfect int means no more pages
    else we check if tobefetchedpage is more then last fetched page
    * */
    final double loadedPages=(reqShelf.files.length+reqShelf.shelfs.length)/Constants.DEFAULT_PAGE_SIZE;
    return (invalidShelf && pageNo==1) || ((pageNo==1 || pageNo<=reqShelf.totalPages!.ceil()) && loadedPages+1==pageNo);
  }



  @override
  List<Object?> get props => [httpStates, _shelf];
}
