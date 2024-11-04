part of 'shelf_bloc.dart';

@immutable
class ShelfState extends Equatable with WithHttpState {
  static const String ROOT_SHELF_ID="0";
  final Set<String?> _invalidatedShelfs;//NULL -> root, shelfId -> shelf
  final Shelf _rootShelf;

  ShelfState({
    Shelf? shelf,
    Set<String?> invalidatedShelfs=const {},
    Map<String,HttpState>? httpStates,
  }) : _rootShelf = shelf ?? Shelf.rootShelf(rootShelfId: ROOT_SHELF_ID),_invalidatedShelfs=invalidatedShelfs{
    this.httpStates.addAll(httpStates ?? {});
  }

  ShelfState copyWith({
    Map<String, HttpState>? httpStates,
    Shelf? shelf,
    Set<String?>? invalidatedShelfs,
  }) {
    return ShelfState(
      invalidatedShelfs: invalidatedShelfs ?? _invalidatedShelfs,
      httpStates: httpStates ?? this.httpStates,
      shelf: shelf ?? _rootShelf
    );
  }

  factory ShelfState.initial() => ShelfState();

  Shelf get rootShelf{
    return _rootShelf;
  }

  Shelf clearShelf({required String? shelfId}){//clear target shelf and return rootshelf
    if(shelfId==null) return Shelf.rootShelf(rootShelfId: ROOT_SHELF_ID);

    final reqShelf=_rootShelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelfId");
    reqShelf
      ..files.clear()
      ..shelfs.clear();
    return _rootShelf;
  }

  isShelfInvalid(String? shelfId){
    return _invalidatedShelfs.contains(shelfId);
  }

  hasPage({String? shelfId,required int pageNo}){
    final Shelf? reqShelf= shelfId==null ? _rootShelf :  _rootShelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelf id");
    return (reqShelf.shelfs.length+reqShelf.files.length)/Constants.DEFAULT_PAGE_SIZE>=pageNo;
  }

  int? canLoadPage({String? shelfId}){
    if(isLoading(forr: Httpstates.ITEMS_IN_SHELF)) return null;

    final Shelf? reqShelf= shelfId==null ? _rootShelf :  _rootShelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelf id");

    if(_invalidatedShelfs.contains(shelfId)) return 1;//load first page
    /*
    if loaded pages is not perfect int means no more pages
    else we check if to be fetched page is more then last fetched page
    * */
    final double loadedPages=(reqShelf.files.length+reqShelf.shelfs.length)/Constants.DEFAULT_PAGE_SIZE;
    if(reqShelf.hasItems() && reqShelf.totalPages==null) throw Exception("Total pages not initialized");

    return (reqShelf.totalPages==null || loadedPages+1<=reqShelf.totalPages!.ceil()) ? loadedPages.ceil()+1 : null;
  }



  @override
  List<Object?> get props => [httpStates, _rootShelf,_invalidatedShelfs];
}
