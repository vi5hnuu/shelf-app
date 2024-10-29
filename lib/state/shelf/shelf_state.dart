part of 'shelf_bloc.dart';

@immutable
class ShelfState extends Equatable with WithHttpState {
  static const defaultPageSize = 15;
  final Shelf _shelf;

  ShelfState({
    Shelf? shelf,
    Map<String,HttpState>? httpStates,
  }) : _shelf = shelf ?? Shelf.rootShelf(){
    this.httpStates.addAll(httpStates ?? {});
  }

  ShelfState copyWith({
    Map<String, HttpState>? httpStates,
    Shelf? shelf,
  }) {
    return ShelfState(
      httpStates: httpStates ?? this.httpStates,
      shelf: shelf ?? _shelf
    );
  }

  factory ShelfState.initial() => ShelfState();

  Shelf get shelf{
    return _shelf;
  }

  hasPage({String? shelfId,required int pageNo}){
    final Shelf? reqShelf= shelfId==null ? _shelf :  _shelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelf id");
    return (reqShelf.shelfs.length+reqShelf.files.length)/defaultPageSize>=pageNo;
  }

  canLoadPage({String? shelfId,required int pageNo}){
    if(isLoading(forr: Httpstates.ITEMS_IN_SHELF)) return false;

    final Shelf? reqShelf= shelfId==null ? _shelf :  _shelf.getShelf(shelfId: shelfId);
    if(reqShelf==null) throw Exception("Invalid shelf id");
    if(reqShelf.totalPages==null) throw Exception("Total pages not initialized");

    /*
    if loaded pages is not perfect int means no more pages
    else we check if tobefetchedpage is more then last fetched page
    * */
    final double loadedPages=(reqShelf.files.length+reqShelf.shelfs.length)/defaultPageSize;
    return (loadedPages.ceil()-loadedPages.floor())==0 && pageNo<=reqShelf.totalPages!.ceil() && loadedPages+1==pageNo;
  }



  @override
  List<Object?> get props => [httpStates, _shelf];
}
