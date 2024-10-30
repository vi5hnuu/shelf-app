import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shelf/constants/constants.dart';
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
      final isShelfInvalid=state.isShelfInvalid(event.shelfId);
      if(!isShelfInvalid && state.hasPage(pageNo: event.pageNo,shelfId: event.shelfId) ||
          !state.canLoadPage(pageNo: event.pageNo)) return emit(state.copyWith());

      if(isShelfInvalid){
        if(event.pageNo!=1) {
          // throw Exception("shelf is invalid, page no must be 1");
          return add(FetchItemsInShelf(shelfId: event.shelfId, pageNo: 1));
        }
        emit(state.copyWith(shelf: state.clearShelf(shelfId: event.shelfId),httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));
      }
      if(!isShelfInvalid)
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));
      try {
        final Pageable<Object> itemsInShelf = await _persistance.getItemsInShelf(shelfId: event.shelfId,limit: Constants.DEFAULT_PAGE_SIZE,pageNo: event.pageNo);

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

        final invalidatedShelfs=isShelfInvalid ? (state._invalidatedShelfs..remove(event.shelfId)) : state._invalidatedShelfs;
        emit(state.copyWith(invalidatedShelfs: invalidatedShelfs,httpStates:state.httpStates.clone()..remove(Httpstates.ITEMS_IN_SHELF), shelf: rootShelf));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF, HttpState.error(error: e.toString()))));
      }
    });
    on<MoveItemsTo>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO,const HttpState.loading())));
      try {
        final movedItemsCount=await _persistance.moveItemsTo(toShelfId: event.toShelfId,fileIds: event.fileIds, shelfIds: event.shelfIds);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.MOVE_ITEMS_TO), invalidatedShelfs: state._invalidatedShelfs..addAll([event.toShelfId,event.parentShelfId])));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO, HttpState.error(error: e.toString()))));
      }
    });
    on<DeleteItems>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.DELETE_ITEMS,const HttpState.loading())));
      try {
        final deletedItemsCount=await _persistance.deleteItems(fileIds: event.fileIds, shelfIds: event.shelfIds, permanentDelete: event.permanentDelete);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.DELETE_ITEMS), invalidatedShelfs: state._invalidatedShelfs..add(event.parentShelfId)));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.DELETE_ITEMS, HttpState.error(error: e.toString()))));
      }
    });
  }

  @override
  void onEvent(ShelfEvent event) {
    super.onEvent(event);
  }

  @override
  void onTransition(Transition<ShelfEvent, ShelfState> transition) {
    if(transition.event is DeleteItems || transition.event is MoveItemsTo){
      String parentShelfId=transition.event is DeleteItems ? (transition.event as DeleteItems).parentShelfId : (transition.event as MoveItemsTo).parentShelfId;
      add(FetchItemsInShelf(shelfId: parentShelfId, pageNo: 1));
    }
    super.onTransition(transition);
  }
}
