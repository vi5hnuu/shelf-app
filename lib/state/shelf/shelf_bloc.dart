import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shelf/extensions/map-entensions.dart';
import 'package:shelf/models/HttpState.dart';
import 'package:shelf/models/Pageable.dart';
import 'package:shelf/singletons/persistance.dart';
import 'package:shelf/state/WithHttpState.dart';
import 'package:shelf/state/httpStates.dart';

import '../../models/shelf.dart';
part 'shelf_event.dart';
part 'shelf_state.dart';

class ShelfBloc extends Bloc<ShelfEvent, ShelfState> {
  final _persistance = Persistance();

  ShelfBloc() : super(ShelfState.initial()) {
    on<FetchItemsInShelf>((event,emit)async{
      if(state.hasPage(pageNo: event.pageNo,shelfId: event.shelfId) ||
          !state.canLoadPage(pageNo: event.pageNo)) return emit(state.copyWith());

      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));
      try {
        final Pageable<Object> itemsInShelf = await _persistance.getItemsInShelf(shelfId: event.shelfId,limit: ShelfState.defaultPageSize,pageNo: event.pageNo);

        final List<Shelf> shelfs=[];
        final List<File> files=[];
        for(final item in itemsInShelf.data){
          if(item is Shelf) {
            shelfs.add(item);
          } else if(item is File) {
            files.add(item);
          }else{
            throw Exception("invalid item type");
          }
        }
        final Shelf rootShelf=state.shelf.addToShelf(shelfId: event.shelfId ?? '0',files:files,shelfs: shelfs );
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.ITEMS_IN_SHELF), shelf: rootShelf));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF, HttpState.error(error: e.toString()))));
      }
    });
    on<MoveItemsTo>((event,emit)async{

    });
    on<DeleteItems>((event,emit)async{});
  }

  @override
  void onEvent(ShelfEvent event) {
    super.onEvent(event);
  }
}
