import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shelf/singletons/LoggerSingleton.dart';
import 'package:shelf/singletons/persistance.dart';
import 'package:shelf/state/httpStates.dart';
import 'package:shelf/state/shelf/shelf_bloc.dart';
import 'package:shelf/widgets/RetryAgain.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
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
            LoggerSingleton().logger.i("did pop $didPop");
              setState(()=>_loadPage(shelfId: (_shelfPaths..removeLast()).lastOrNull,pageNo: 1));
          },
          canPop: _shelfPaths.isEmpty,
          child: Scaffold(
              appBar: AppBar(
                title: Text(
                  "Shelf - ${shelfId ?? 'ROOT'}",
                  style: const TextStyle(color: Colors.white, fontFamily: "Kalam", fontSize: 18, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              floatingActionButton: IconButton(icon: Icon(Icons.add),onPressed: () {
                showModalBottomSheet(
                  enableDrag: true,
                  context: context,
                  showDragHandle: true,
                  isDismissible: true,
                  sheetAnimationStyle: AnimationStyle(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.bounceIn,
                    reverseDuration: Duration(milliseconds: 300),
                    reverseCurve: Curves.elasticInOut),
                  elevation: 1,
                  useSafeArea: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  builder: (context) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      width: double.infinity,
                      height: 100,
                      child: Text("data"),
                    );
                  });
            },),
              body: BlocConsumer<ShelfBloc, ShelfState>(
              listener: (context, state) {},
              buildWhen: (previous, current) => previous != current,
              listenWhen: (previous, current) => previous != current,
              builder: (context, state) {
                final shelf=state.shelf.getShelf(shelfId: shelfId ?? ShelfState.ROOT_SHELF_ID);
                final totalItems=shelf!=null ? (shelf.shelfs.length+shelf.files.length):0;
                return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(onPressed: (){
                      Persistance().createDummyData(0,3,null);
                    }, child: Text("create folder")),
                    if(shelf!=null && shelf.hasItems()) Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4,crossAxisSpacing: 10,mainAxisSpacing: 10),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if(index<shelf.shelfs.length){
                            final nestedShelf=shelf.shelfs[index];
                            return GestureDetector(
                              onDoubleTap: ()=>_goToShelf(nestedShelf.id),
                              child: Card(child: Text(nestedShelf.title),shadowColor: Colors.red,),
                            );
                          }else{
                            final file=shelf.files[index-shelf.shelfs.length];
                            return GestureDetector(
                              child: Card(child: Text(file.title),shadowColor: Colors.green,),
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
                );})),
        );
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
    setState(()=>_loadPage(shelfId:(_shelfPaths..add(id)).last,pageNo: 1));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_loadNextPage);
    _scrollController.dispose();
    super.dispose();
  }

}
