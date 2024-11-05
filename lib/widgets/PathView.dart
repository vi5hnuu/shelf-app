import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shelf/models/shelf.dart';

class PathView extends StatelessWidget {
  PathView({
    super.key,
    required this.paths,
    this.onPathClick
  });

  final Function(String shelfId)? onPathClick;
  final List<Shelf> paths;
  final ScrollController _scrollController = ScrollController();
  final double fontSize=24;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients)return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children:paths.length==1 ? [Text("/",style:TextStyle(fontWeight: FontWeight.bold,fontSize: fontSize) ,)] : paths.map((path)=>[if(path!=paths.first) Text("/",style: TextStyle(fontWeight: FontWeight.bold,fontSize: fontSize),), GestureDetector(onTap: onPathClick==null ? null : ()=>onPathClick!(path.id),
              child: Text(path.title,style: TextStyle(color: onPathClick!=null ? Colors.blue:Colors.grey,fontSize: fontSize)))]).expand((items)=>items).toList()),);
  }
}
