import 'dart:async';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shelf/constants/constants.dart';
import 'package:shelf/extensions/string-entensions.dart';
import 'package:shelf/models/shelf.dart';
import 'package:shelf/singletons/LoggerSingleton.dart';
import 'package:shelf/singletons/NotificationService.dart';
import 'package:shelf/singletons/persistance/persistance.dart';
import 'package:shelf/state/httpStates.dart';
import 'package:shelf/state/shelf/shelf_bloc.dart';
import 'package:shelf/widgets/CreateShelfDialog.dart';
import 'package:shelf/widgets/FileView.dart';
import 'package:shelf/widgets/PathView.dart';
import 'package:shelf/widgets/RetryAgain.dart';
import 'package:shelf/widgets/ShelfView.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late final GoRouter _router=GoRouter.of(context);
  final List<String> _shelfPaths=[];//path to current shelf
  final ScrollController _scrollController = ScrollController();
  late final ShelfBloc _shelfBloc;
  int pageNo = 1;

  @override
  void initState() {
    _shelfBloc=BlocProvider.of<ShelfBloc>(context);
    _loadPage(shelfId:null,pageNo:1);
    _scrollController.addListener(_loadNextPage);
    super.initState();
  }

  String? get shelfId{
    return (_shelfPaths.isNotEmpty ? _shelfPaths.last : null);
  }

  @override
  Widget build(BuildContext context) {
    final _router=GoRouter.of(context);

        return PopScope(
          onPopInvokedWithResult: (didPop, result) {
              setState(()=>_loadPage(shelfId: (_shelfPaths..removeLast()).lastOrNull,pageNo: 1));
          },
          canPop: _shelfPaths.isEmpty,
          child: BlocConsumer<ShelfBloc, ShelfState>(
              listener: (context, state) {},
              buildWhen: (previous, current) => previous != current,
              listenWhen: (previous, current) => previous != current,
              builder: (context, state) {
                final List<Shelf> paths=[];
                final shelf=state.rootShelf.getShelf(shelfId: shelfId ?? ShelfState.ROOT_SHELF_ID,path: paths)!;
                final totalItems=(shelf.shelfs.length+shelf.files.length);
                return Scaffold(
              appBar: AppBar(
                title: Text(
                  shelf.title.isNotEmpty ? shelf.title.capitalize() : 'HOME',
                  softWrap: false,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 24, fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis,letterSpacing: 1),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              floatingActionButton: IconButton.filled(icon: const Icon(FontAwesomeIcons.ellipsisVertical,size: 24,),
                  padding: const EdgeInsets.all(16),
                  onPressed: ()=>_openShelfActions(context)),
              body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PathView(onPathClick: (sid) {
                      _goToShelf(sid);
                    },paths: paths),
                    const SizedBox(height: 12,),
                    if(state.isLoading(forr: Httpstates.SAVING_FILES_IN_SHELF))
                      const SpinKitThreeBounce(color: Colors.green,size: 24)
                    else if(shelf.hasItems()) Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                        childAspectRatio: 1),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if(index<shelf.shelfs.length){
                            final nestedShelf=shelf.shelfs[index];
                            return GestureDetector(
                              onDoubleTap: ()=>_goToShelf(nestedShelf.id),
                              child: ShelfView(svgPath: "assets/svg/shelf.svg",title: nestedShelf.title,),
                            );
                          }else{
                            final file=shelf.files[index-shelf.shelfs.length];
                            return GestureDetector(
                              onTap: () => _openFile(file: file),
                              child: FileView(svgPath: Constants.getFileSvgPath(SupportedFileType.toEnum(file.type)),title: file.title),
                            );
                          }
                        }
                      ),
                    )
                    else if(!state.isLoading(forr: Httpstates.ITEMS_IN_SHELF) && !shelf.hasItems()) const Text("Create shelf/ Add files ⭐📚",textAlign: TextAlign.center,style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold)),
                    Container(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: (state.isLoading(forr: Httpstates.ITEMS_IN_SHELF))
                          ? Padding(padding: const EdgeInsets.symmetric(vertical: 20),child: SpinKitThreeBounce(color: Theme.of(context).primaryColor, size: 24))
                          : ((state.isError(forr: Httpstates.ITEMS_IN_SHELF))
                              ? RetryAgain(
                                  onRetry: ()=>_loadPage(shelfId: shelfId, pageNo: pageNo),
                                  error: state
                                      .getError(forr: Httpstates.ITEMS_IN_SHELF)!)
                              : null),
                    )
                  ],
                ),
                ));}),
        );
  }

  void _openShelfActions(BuildContext context) {
    showModalBottomSheet(
      enableDrag: true,
      context: context,
      showDragHandle: true,
      isDismissible: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 500),
        curve: Curves.bounceIn,
        reverseDuration: const Duration(milliseconds: 300),
        reverseCurve: Curves.elasticInOut),
      elevation: 1,
      useSafeArea: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          width: double.infinity,
          height: 200,
          child: GridView.count(crossAxisCount: 4,children: [
            IconButton(onPressed: ()=>showDialog(context: context,builder: (context) {
              return CreateShelfDialog(shelfId:shelfId);
            },barrierDismissible: true,useSafeArea: true).then((value) => _router.pop()),
                icon: const Icon(FontAwesomeIcons.folderPlus,size: 36,color: Colors.orangeAccent)),
            IconButton(onPressed: () async {
              await onFileSelection();
              if(mounted) GoRouter.maybeOf(context)?.pop();
            },
                icon: const Icon(FontAwesomeIcons.fileCirclePlus,size: 36,color: Colors.orangeAccent))
          ]),
        );
      });
  }

  onFileSelection() async{
    try{
      List<PlatformFile> pFiles = await _pickFiles();
      _shelfBloc.add(SaveFilesInShelf(shelfId: shelfId, files: pFiles.map((file)=>CreateFileItem(file: file,tags: [])).toList()));
    }catch(e){
      NotificationService.showSnackbar(text: (e is String) ? e : "something went wrong");
    }
  }

  void _loadPage({required String? shelfId,required int pageNo}) {
    _shelfBloc.add(FetchItemsInShelf(shelfId: shelfId,pageNo: pageNo));
  }

  void _loadNextPage() {
    double maxScrollExtent = _scrollController.position.maxScrollExtent;
    double currentScrollPosition = _scrollController.position.pixels;
    // Calculate the scroll percentage
    double scrollPercentage = currentScrollPosition / maxScrollExtent;
    // Check if scroll percentage is greater than or equal to 80%
    if (scrollPercentage <= 0.8) return;
    final canLoadNextPage = _shelfBloc.state.canLoadPage(pageNo: pageNo+1,shelfId: shelfId);
    if(canLoadNextPage) setState(() => _loadPage(shelfId: shelfId,pageNo: ++pageNo));
  }

  _goToShelf(String id) {
    final exIndex=_shelfPaths.indexOf(id);
    while(exIndex!=-1 && (_shelfPaths.length-1)>=exIndex) _shelfPaths.removeLast();
    setState(()=>_loadPage(shelfId:(_shelfPaths..add(id)).last,pageNo: 1));
  }

  Future<List<PlatformFile>> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: SupportedFileType.values.map((fileType)=>fileType.type as String).toList(),
        dialogTitle: "Select Files For Shelf",
        lockParentWindow: true,
        withReadStream: true
      );
      if(result==null || result.files.isEmpty) throw "File Selection cancelled.";
      return Future.value(result.files);
    } catch (e) {
      rethrow;
    }
  }

  _openFile({required File file}) async {
    final OpenResult openResult= await OpenFile.open(file.filePath);
    switch(openResult.type){
      case ResultType.fileNotFound:return NotificationService.showSnackbar(text: "file ${file.title} not found.");
      case ResultType.error:return NotificationService.showSnackbar(text: openResult.message);
      case ResultType.done:return NotificationService.showSnackbar(text: "file ${file.title} opened.",color: Colors.green);
      case ResultType.noAppToOpen:return NotificationService.showSnackbar(text: "There is no app found to open ${file.title}.",color: Colors.yellow);
      case ResultType.permissionDenied:return NotificationService.showSnackbar(text: "Permission denied");
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadNextPage);
    _scrollController.dispose();
    super.dispose();
  }

}