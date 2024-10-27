part of 'shelf_bloc.dart';

@immutable
class ShelfState extends Equatable with WithHttpState {
  static const defaultPageSize = 15;
  List<>

  ShelfState({
    Map<String,HttpState>? httpStates,
  })  : _mantras = mantras,
        _mantraInfo = mantraInfo,
        _mantraAudioInfo=mantraAudioInfo,
        _mantrasAudios=mantraAudios{
    this.httpStates.addAll(httpStates ?? {});
  }

  ShelfState copyWith({
    Map<String, HttpState>? httpStates,
    Map<String, MantraInfoModel>? mantraInfo,
    Map<String, MantraGroupModel>? mantras,
    MantraAudioPageModel? mantraAudioInfo,
    Map<String, MantraAudioModel>? mantraAudios,
  }) {
    return ShelfState(
      httpStates: httpStates ?? this.httpStates,
      mantraInfo: mantraInfo ?? this._mantraInfo,
      mantraAudioInfo: mantraAudioInfo ?? this._mantraAudioInfo,
      mantraAudios: mantraAudios ?? this._mantrasAudios,
      mantras: mantras ?? this._mantras,
    );
  }

  factory ShelfState.initial() => ShelfState();

  Map<String, MantraInfoModel>? get allMantraInfo => _mantraInfo != null ? Map.unmodifiable(_mantraInfo) : null;

  Map<String, MantraGroupModel> get allMantras => Map.unmodifiable(_mantras);

  MantraAudioPageModel? get allMantraAudioInfo => _mantraAudioInfo;

  Map<String, MantraAudioModel> get allMantrasAudios => Map.unmodifiable(_mantrasAudios);

  MantraAudioModel? nextAudio({required String mantraAudioId}){
    try{
      final mantraAudio=allMantrasAudios.values.indexed.firstWhere((element) => element.$2.id==mantraAudioId);
      return mantraAudio.$1+1<allMantrasAudios.length ? allMantrasAudios.values.elementAt(mantraAudio.$1+1):null;
    }catch(err){
      throw new Exception("dev error");
    }
  }
  MantraAudioModel? previousAudio({required String mantraAudioId}){
    try{
      final mantraAudio=allMantrasAudios.values.indexed.firstWhere((element) => element.$2.id==mantraAudioId);
      return mantraAudio.$1-1>=0 ? allMantrasAudios.values.elementAt(mantraAudio.$1-1):null;
    }catch(err){
      throw new Exception("dev error");
    }
  }

  bool mantraExists({required String mantraId}) => _mantras.containsKey(mantraId);

  bool mantraAudioExists({required String mantraAudioId}) => _mantrasAudios.containsKey(mantraAudioId);

  bool hasMantraAudioPage({required int pageNo}){
    return _mantraAudioInfo?.data.length!=null && _mantraAudioInfo!.data.length>=pageNo*ShelfState.defaultMantraAudioInfoPageSize;
  }
  bool canLoadMantraAudioPage({required int pageNo}){
    return httpStates[mantraAudioInfoPageKey(pageNo: pageNo)]?.loading!=true && !hasMantraAudioPage(pageNo: pageNo) && loadedPageCount+1==pageNo;
  }

  get loadedPageCount{
    return (_mantraAudioInfo?.data.length ?? 0)/ShelfState.defaultMantraAudioInfoPageSize;
  }

  MantraGroupModel? getMantraById({required String mantraId}) => _mantras[mantraId];
  MantraAudioModel? getMantraAudioById({required String mantraAudioId}) => _mantrasAudios[mantraAudioId];

  MapEntry<String, MantraGroupModel> getMantraEntry({required MantraGroupModel mantra}) => MapEntry(mantra.id, mantra);
  MapEntry<String, MantraAudioModel> getMantraAudioEntry({required MantraAudioModel mantraAudio}) => MapEntry(mantraAudio.id, mantraAudio);

  @override
  List<Object?> get props => [httpStates, _mantraInfo, _mantras,_mantrasAudios,_mantraAudioInfo];

  String mantraAudioInfoPageKey({required int pageNo}) {
    return 'mantra-audio-page-${pageNo}';
  }
}
