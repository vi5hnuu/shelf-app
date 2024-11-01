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
  late final GoRouter router=GoRouter.of(context);
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
  
  get shelfId{
    return (_shelfPaths.isNotEmpty ? _shelfPaths.last : null);
  }

  @override
  Widget build(BuildContext context) {
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
                final shelf=state.shelf.getShelf(shelfId: shelfId ?? ShelfState.ROOT_SHELF_ID,path: paths)!;
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
                    if(state.isLoading(forr: Httpstates.SAVING_FILES_IN_SHELF)) Text("saving files please wait"),
                    PathView(onPathClick: (sid) {
                      _goToShelf(sid);
                    },paths: paths),
                    if(shelf.hasItems()) Expanded(
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
                              child: Shelfview(svgPath: "assets/svg/shelf.svg"),
                            );
                          }else{
                            final file=shelf.files[index-shelf.shelfs.length];
                            return GestureDetector(
                              onTap: () => _openFile(file: file),
                              child: FileView(svgPath: Constants.getFileSvgPath(SupportedFileType.toEnum(file.type))),
                            );
                          }
                        }
                      ),
                    ),
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
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),side: BorderSide.none),
                  insetPadding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Create Shelf",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),),
                        const SizedBox(height: 24),
                        const CustomTextField(initialValue: "title",label: "Enter shelf title",),
                        const SizedBox(height: 12),
                        const CustomTextField(initialValue: "description",label: "Enter shelf description",),
                        const SizedBox(height: 12),
                        const CustomTextField(initialValue: "self help,personal",label: "Enter shelf tags seperated by ,",),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end
                          ,children: [
                          FilledButton(onPressed: () {

                          },style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)), child: const Text("Cancel"),),
                          const SizedBox(width: 12),
                          FilledButton(onPressed: () {

                          },style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)), child: const Text("Create")),
                          ],)
                      ],),
                  ),
                  ),
              );
            },barrierDismissible: true,useSafeArea: true),
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


class CustomTextField extends StatelessWidget {
  final String label;
  final String? initialValue;

  const CustomTextField({
    super.key,
    required this.label,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(initialValue: initialValue,decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(), // Outlined border for TextField
                    focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.grey, width: 1.5),
                    ),
                    hintText: 'Type something...',
                  ),);
  }
}
