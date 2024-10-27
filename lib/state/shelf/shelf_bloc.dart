import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:shelf/models/HttpState.dart';
part 'shelf_event.dart';
part 'shelf_state.dart';

class ShelfBloc extends Bloc<ShelfEvent, ShelfState> {
  ShelfBloc() : super(ShelfState.initial()) {
    on<FetchAllMantraInfo>((event, emit) async {
      if (state.allMantraInfo != null) return emit(state.copyWith(httpStates:  state.httpStates.clone()..remove(Httpstates.ALL_MANTRA_INFO)));
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ALL_MANTRA_INFO,const HttpState.loading())));
      try {
        final mantrasInfo = await mantraRepository.getAllMantraInfo(cancelToken: event.cancelToken);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.ALL_MANTRA_INFO), mantraInfo: Map.fromEntries(mantrasInfo.data!.map((mantraInfo) => MapEntry(mantraInfo.id, mantraInfo)))));
      }  on DioException catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ALL_MANTRA_INFO, HttpState.error(error: Utils.handleDioException(e)))));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.ALL_MANTRA_INFO, HttpState.error(error: ErrorModel(message:e.toString())))));
      }
    });
    on<FetchAllMantraAudioInfo>((event, emit) async {
      if (!state.canLoadMantraAudioPage(pageNo:event.pageNo)) return emit(state.copyWith());
      emit(state.copyWith(httpStates: state.httpStates.clone(withh:MapEntry(state.mantraAudioInfoPageKey(pageNo: event.pageNo), const HttpState.loading()))));
      try {
        final mantrasAudioInfo = await mantraRepository.getAllMantraAudioInfo(pageNo: event.pageNo,pageSize: ShelfState.defaultMantraAudioInfoPageSize,cancelToken: event.cancelToken);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(state.mantraAudioInfoPageKey(pageNo: event.pageNo)), mantraAudioInfo: MantraAudioPageModel(data: [...(state._mantraAudioInfo?.data??[]),...mantrasAudioInfo.data!.data], total: mantrasAudioInfo.data!.total)));
      }  on DioException catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(state.mantraAudioInfoPageKey(pageNo: event.pageNo), HttpState.error(error: Utils.handleDioException(e)))));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(state.mantraAudioInfoPageKey(pageNo: event.pageNo), HttpState.error(error: ErrorModel(message:e.toString())))));
      }
    });
    on<FetchAllMantra>((event, emit) {
      // TODO: implement event handler
    });
    on<FetchMantraById>((event, emit) async {
      if (state.mantraExists(mantraId: event.id)) return emit(state.copyWith(httpStates:  state.httpStates.clone()..remove(Httpstates.MANTRA_BY_ID)));
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MANTRA_BY_ID,const HttpState.loading())));
      try {
        final mantraData = await mantraRepository.getMantraById(id: event.id, cancelToken: event.cancelToken);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.MANTRA_BY_ID), mantras: Map.fromEntries([...state.allMantras.entries, state.getMantraEntry(mantra: mantraData.data!)])));
      }  on DioException catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MANTRA_BY_ID, HttpState.error(error: Utils.handleDioException(e)))));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MANTRA_BY_ID, HttpState.error(error: ErrorModel(message:e.toString())))));
      }
    });
    on<FetchMantraAudioById>((event, emit) async {
      if (state.mantraAudioExists(mantraAudioId: event.id)) return emit(state.copyWith(httpStates:  state.httpStates.clone()..remove(Httpstates.MANTRA_AUDIO_BY_ID)));
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MANTRA_AUDIO_BY_ID,const HttpState.loading())));
      try {
        final mantraAudioData = await mantraRepository.getMantraAudioById(id: event.id, cancelToken: event.cancelToken);
        emit(state.copyWith(httpStates:state.httpStates.clone()..remove(Httpstates.MANTRA_AUDIO_BY_ID), mantraAudios: Map.fromEntries([...state.allMantrasAudios.entries, state.getMantraAudioEntry(mantraAudio: mantraAudioData.data!)])));
      }  on DioException catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MANTRA_AUDIO_BY_ID, HttpState.error(error: Utils.handleDioException(e)))));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(Httpstates.MANTRA_AUDIO_BY_ID, HttpState.error(error: ErrorModel(message:e.toString())))));
      }
    });
    on<FetchMantraByTitle>((event, emit) {
      // TODO: implement event handler
    });
    on<FetchMantraAudioByTitle>((event, emit) {
      // TODO: implement event handler
    });
  }
}
