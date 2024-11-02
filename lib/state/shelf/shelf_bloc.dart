import 'dart:io' as io;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/constants/constants.dart';
import 'package:shelf/extensions/map-entensions.dart';
import 'package:shelf/extensions/set-entensions.dart';
import 'package:shelf/models/HttpState.dart';
import 'package:shelf/models/Pageable.dart';
import 'package:shelf/singletons/persistance/model/create-file.dart';
import 'package:shelf/singletons/persistance/persistance.dart';
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
      if(!state.canLoadPage(shelfId: event.shelfId,pageNo: event.pageNo)) return emit(state.copyWith());

      if(isShelfInvalid){
        if(event.pageNo!=1) {
          // throw Exception("shelf is invalid, page no must be 1");
          return add(FetchItemsInShelf(shelfId: event.shelfId, pageNo: 1));
        }
        emit(state.copyWith(shelf: state.clearShelf(shelfId: event.shelfId),httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));
      }
      if(!isShelfInvalid)
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));

      //TODO ::  remove this test line
      await Future.delayed(Duration(seconds: 2));
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
        final Shelf rootShelf=state.rootShelf
            .addToShelf(shelfId: event.shelfId ?? ShelfState.ROOT_SHELF_ID,files:files,shelfs: shelfs,totalPages: itemsInShelf.totalPages);
        final invalidatedShelfs=isShelfInvalid ? (state._invalidatedShelfs.clone()..remove(event.shelfId)) : state._invalidatedShelfs.clone();
        emit(state.copyWith(invalidatedShelfs: invalidatedShelfs,httpStates:state.httpStates.clone()..remove(Httpstates.ITEMS_IN_SHELF), shelf: rootShelf));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF, HttpState.error(error: e.toString()))));
      }
    });
    on<MoveItemsTo>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO,const HttpState.loading())));
      try {
        final movedItemsCount=await _persistance.moveItemsTo(toShelfId: event.toShelfId,fileIds: event.fileIds, shelfIds: event.shelfIds);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.MOVE_ITEMS_TO), invalidatedShelfs: state._invalidatedShelfs.clone()..addAll([event.toShelfId,event.parentShelfId])));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO, HttpState.error(error: e.toString()))));
      }
    });
    on<DeleteItems>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.DELETE_ITEMS,const HttpState.loading())));
      try {
        final deletedItemsCount=await _persistance.deleteItems(fileIds: event.fileIds, shelfIds: event.shelfIds, permanentDelete: event.permanentDelete);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.DELETE_ITEMS), invalidatedShelfs: state._invalidatedShelfs.clone()..add(event.parentShelfId)));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.DELETE_ITEMS, HttpState.error(error: e.toString()))));
      }
    });
    on<SaveFilesInShelf>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.SAVING_FILES_IN_SHELF,const HttpState.loading())));
      try {
        //same file save twice -> single entry in app_dir but 2 entry in db [take care while deleting]
        List<CreateFile> toSaveFiles = await saveFilesIn(event.shelfId,event.files);
        await _persistance.createFiles(files: toSaveFiles);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.SAVING_FILES_IN_SHELF), invalidatedShelfs: state._invalidatedShelfs.clone()..add(event.shelfId)));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.SAVING_FILES_IN_SHELF, HttpState.error(error: e.toString()))));
      }
    });
    on<CreateShelfIn>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.CREATE_SHELF,const HttpState.loading())));
      try {
        //same file save twice -> single entry in app_dir but 2 entry in db [take care while deleting]
        await _persistance.createShelf(parentShelfId: event.shelfId,
          title: event.title,description: event.description,coverImage: event.coverImage,tags: event.tags);

        //TODO::remove this test line
        await Future.delayed(Duration(seconds: 3));
        emit(state.copyWith(httpStates:state.httpStates.clone()..put(Httpstates.CREATE_SHELF,const HttpState.done()), invalidatedShelfs: state._invalidatedShelfs.clone()..add(event.shelfId)));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.CREATE_SHELF, HttpState.error(error: e.toString()))));
      }
    });
  }

  Future<List<CreateFile>> saveFilesIn(String? shelfId,List<CreateFileItem> createFileItems) async {
      io.Directory appDocDir = await getApplicationDocumentsDirectory();

      List<CreateFile> savedFiles = [];
      for (var createFileItem in createFileItems) {
        if (createFileItem.file.readStream == null) continue;
        String newFilePath = "${appDocDir.path}/${createFileItem.file.name}";
        io.File newFile = io.File(newFilePath);

        // Open a sink for writing to the new file
        io.IOSink sink = newFile.openWrite();

        // Listen to stream and write to file in chunks
        await createFileItem.file.readStream!.forEach((chunk) => sink.add(chunk));
        await sink.close();
        savedFiles.add(CreateFile(shelfId: shelfId,
            filePath: newFilePath,
            title: createFileItem.file.name,
            type: createFileItem.file.extension ?? 'txt',
            size: createFileItem.file.size)); // Store saved path
      }
      return savedFiles;
  }

  @override
  void onEvent(ShelfEvent event) {
    super.onEvent(event);
  }

  @override
  void onTransition(Transition<ShelfEvent, ShelfState> transition) {
    super.onTransition(transition);
    if((transition.event is DeleteItems || transition.event is MoveItemsTo) && !transition.nextState.hasAnyHttpState(forr: [Httpstates.DELETE_ITEMS,Httpstates.MOVE_ITEMS_TO])){
      String parentShelfId=transition.event is DeleteItems ? (transition.event as DeleteItems).parentShelfId : (transition.event as MoveItemsTo).parentShelfId;
      add(FetchItemsInShelf(shelfId: parentShelfId, pageNo: 1));
    }else if(transition.event is SaveFilesInShelf && !transition.nextState.hasHttpState(forr: Httpstates.SAVING_FILES_IN_SHELF)){
      add(FetchItemsInShelf(shelfId: (transition.event as SaveFilesInShelf).shelfId, pageNo: 1));
    }else if(transition.event is CreateShelfIn && transition.nextState.isDone(forr: Httpstates.CREATE_SHELF)){
      add(FetchItemsInShelf(shelfId: (transition.event as CreateShelfIn).shelfId, pageNo: 1));
    }
  }

}
