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
import 'package:path/path.dart' as path;
import '../../models/shelf.dart';
part 'shelf_event.dart';
part 'shelf_state.dart';

class ShelfBloc extends Bloc<ShelfEvent, ShelfState> {
  final _persistance = Persistance();

  ShelfBloc() : super(ShelfState.initial()) {
    on<FetchNextItemsInShelf>((event,emit)async{
      final isShelfInvalid=state.isShelfInvalid(event.shelfId);
      final int? nextPage=state.canLoadPage(shelfId: event.shelfId);
      if(nextPage==null) return emit(state.copyWith());

      if(isShelfInvalid){
        if(nextPage!=1) {
          throw Exception("shelf is invalid, page no must be 1");
        }
        emit(state.copyWith(shelf: state.clearShelf(shelfId: event.shelfId),httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));
      }else{
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.loading())));
      }

      //TODO ::  remove this test line
      await Future.delayed(Duration(milliseconds: 500));
      try {
        final Pageable<Object> itemsInShelf = await _persistance.getItemsInShelf(shelfId: event.shelfId==ShelfState.ROOT_SHELF_ID ? null:event.shelfId,limit: Constants.DEFAULT_PAGE_SIZE,pageNo: nextPage);

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
        emit(state.copyWith(invalidatedShelfs: invalidatedShelfs,httpStates:state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF,const HttpState.done()), shelf: rootShelf));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ITEMS_IN_SHELF, HttpState.error(error: e.toString()))));
      }
    });
    on<MoveItemsTo>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO,const HttpState.loading())));
      try {
        final movedItemsCount=await _persistance.moveItemsTo(toShelfId: event.toShelfId,fileIds: event.fileIds, shelfIds: event.shelfIds);
        emit(state.copyWith(httpStates:state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO,const HttpState.done()), invalidatedShelfs: state._invalidatedShelfs.clone()..addAll([event.toShelfId,event.parentShelfId])));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MOVE_ITEMS_TO, HttpState.error(error: e.toString()))));
      }
    });
    on<DeleteItems>((event,emit)async{
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.DELETE_ITEMS,const HttpState.loading())));
      try {
        List<String> toBeDeltedFilePaths=[];

        toBeDeltedFilePaths=await _persistance.getFilePaths(parentShelfId:event.parentShelfId,fileIds: event.fileIds, shelfIds: event.shelfIds);

        //delete from db
        await _persistance.deleteItems(parentShelfId:event.parentShelfId,fileIds: event.fileIds, shelfIds: event.shelfIds);

        //delete from storage
        await deleteFilesAt(paths:toBeDeltedFilePaths);

        emit(state.copyWith(httpStates:state.httpStates.clone()..put(Httpstates.DELETE_ITEMS,const HttpState.done()), invalidatedShelfs: state._invalidatedShelfs.clone()..add(event.parentShelfId)));
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
        emit(state.copyWith(httpStates:state.httpStates.clone()..put(Httpstates.SAVING_FILES_IN_SHELF,const HttpState.done()), invalidatedShelfs: state._invalidatedShelfs.clone()..add(event.shelfId)));
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
        await Future.delayed(Duration(milliseconds: 500));
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

        //if file exists with this name append random text
        String fileNameWithoutExtension=path.basename(createFileItem.file.path!);
        String newFileName = createFileItem.file.name;

        // Check if a file with the same name already exists, and add a counter if needed
        int count=0;
        while (await io.File(path.join(appDocDir.path,newFileName)).exists()) {
          newFileName = "$fileNameWithoutExtension($count)${createFileItem.file.extension}";
          count++;
        }
        final filePath=path.join(appDocDir.path,newFileName);
        io.File newFile = io.File(filePath);

        // Open a sink for writing to the new file
        io.IOSink sink = newFile.openWrite();

        // Listen to stream and write to file in chunks
        await createFileItem.file.readStream!.forEach((chunk) => sink.add(chunk));
        await sink.close();
        savedFiles.add(CreateFile(shelfId: shelfId,
            filePath: filePath,
            title: newFileName,
            type: createFileItem.file.extension ?? 'txt',
            size: createFileItem.file.size)); // Store saved path
      }
      return savedFiles;
  }

  Future<void> deleteFilesAt({required List<String> paths}) async{
    for(final filePath in paths){
      io.File tobeDeletedFile = io.File(filePath);
      if(!await tobeDeletedFile.exists()) return;
      await tobeDeletedFile.delete();
    }
  }

  @override
  void onEvent(ShelfEvent event) {
    super.onEvent(event);
  }

  @override
  void onTransition(Transition<ShelfEvent, ShelfState> transition) {
    super.onTransition(transition);
    if(transition.event is DeleteItems && transition.nextState.isDone(forr: Httpstates.DELETE_ITEMS)){
      String parentShelfId=(transition.event as DeleteItems).parentShelfId;
      add(FetchNextItemsInShelf(shelfId: parentShelfId));
    }else if(transition.event is MoveItemsTo && transition.nextState.isDone(forr: Httpstates.MOVE_ITEMS_TO)){
      String parentShelfId=(transition.event as MoveItemsTo).parentShelfId;
      add(FetchNextItemsInShelf(shelfId: parentShelfId));
    }else if(transition.event is SaveFilesInShelf && transition.nextState.isDone(forr: Httpstates.SAVING_FILES_IN_SHELF)){
      add(FetchNextItemsInShelf(shelfId: (transition.event as SaveFilesInShelf).shelfId));
    }else if(transition.event is CreateShelfIn && transition.nextState.isDone(forr: Httpstates.CREATE_SHELF)){
      add(FetchNextItemsInShelf(shelfId: (transition.event as CreateShelfIn).shelfId));
    }else if(transition.event is DeleteItems && transition.nextState.isDone(forr: Httpstates.DELETE_ITEMS)){
      add(FetchNextItemsInShelf(shelfId: (transition.event as DeleteItems).parentShelfId));
    }
  }
}
