import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shelf/singletons/persistance/persistance.dart';
import 'package:shelf/state/shelf/shelf_bloc.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {

  @override
  void initState() {
    BlocProvider.of<ShelfBloc>(context).add(FetchItemsInShelf(shelfId: null, pageNo: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ShelfBloc, ShelfState>(
        listener: (context, state) {},
        buildWhen: (previous, current) => previous != current,
        listenWhen: (previous, current) => previous != current,
        builder: (context, state) {
          final shelf=state.rootShelf;
          return GridView.count(
            crossAxisCount: 4,
            children: [
              FilledButton(onPressed: (){
              }, child: Text("create folder")),
              ...shelf.shelfs.map((shelf)=>GestureDetector(
                child: Draggable(child: Card(child: Text(shelf.title),shadowColor: Colors.red,),
                feedback: Card(child: Text(shelf.title),shadowColor: Colors.red,elevation: 10,),
                maxSimultaneousDrags:1000,),
              )),
              ...shelf.files.map((file)=>GestureDetector(
                child: Card(child: Text(file.title),shadowColor: Colors.green,),
              ))
            ],
          );
        },
      ),
    );
  }
}
