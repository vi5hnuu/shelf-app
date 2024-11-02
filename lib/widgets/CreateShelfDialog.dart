import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:shelf/extensions/string-entensions.dart';
import 'package:shelf/models/HttpState.dart';
import 'package:shelf/screens/FileManagerScreen.dart';
import 'package:shelf/singletons/LoggerSingleton.dart';
import 'package:shelf/singletons/NotificationService.dart';
import 'package:shelf/state/httpStates.dart';
import 'package:shelf/state/shelf/shelf_bloc.dart';
import 'package:shelf/widgets/CustomTextField.dart';

class CreateShelfDialog extends StatefulWidget {
  final String? shelfId;

  const CreateShelfDialog({
    super.key,
    required this.shelfId
  });

  @override
  State<CreateShelfDialog> createState() => _CreateShelfDialogState();
}

class _CreateShelfDialogState extends State<CreateShelfDialog> {
  final _createShelfKey = GlobalKey<FormState>();

  final shelfCntrls={
    'title':TextEditingController(text: ""),
    'description':TextEditingController(text: ""),
    'tags':TextEditingController(text: ""),
  };

  @override
  Widget build(BuildContext context) {
    final _router=GoRouter.of(context);
    final _shelfBloc=BlocProvider.of<ShelfBloc>(context);

    return BlocConsumer<ShelfBloc,ShelfState>(
      listenWhen: (previous, current) => previous.httpStates[Httpstates.CREATE_SHELF]!=current.httpStates[Httpstates.CREATE_SHELF],
      listener: (context, state) {
        if(state.isError(forr: Httpstates.CREATE_SHELF)) {
          NotificationService.showSnackbar(text: "Failed to create shelf");
        } else if(state.isDone(forr: Httpstates.CREATE_SHELF)) {
          NotificationService.showSnackbar(text: "created shelf");
          _router.pop();
        }
      },
      buildWhen: (previous, current) => previous.httpStates[Httpstates.CREATE_SHELF]!=current.httpStates[Httpstates.CREATE_SHELF],
      builder: (context, state) {

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),side: BorderSide.none),
          insetPadding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(24),
            child:Form(
                key: _createShelfKey,
                onChanged: () {
                  // LoggerSingleton().logger.i(_createShelfKey.currentState);
                },
                autovalidateMode:AutovalidateMode.onUserInteraction ,
                child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Create Shelf",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),),
                    const SizedBox(height: 24),
                    CustomTextField(
                        controller: shelfCntrls['title'],
                        label: "Enter shelf title",
                        validator: (value) {
                          if (value != null && value.isNotEmpty) return null;
                          return "Invalid shelf title";
                        }),
                    const SizedBox(height: 12),
                    CustomTextField(
                        controller: shelfCntrls['description'],
                        label: "Enter shelf description"),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller:shelfCntrls['tags'],
                      label: "Enter shelf tags seperated by ,",
                      validator: (value) {
                        if((value!=null && value.isNotEmpty) && value.split(',').any((tag) => tag.isBlank)) return "Invalid tags";
                        return null;
                      },),
                    const SizedBox(height: 24),
                    if(state.isLoading(forr: Httpstates.CREATE_SHELF)) const SpinKitThreeBounce(color: Colors.green,size: 24,)
                    else Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end
                      ,children: [
                      FilledButton(onPressed: ()=>_router.pop(),
                          style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
                          child: const Text("Cancel")),
                      const SizedBox(width: 12),
                      FilledButton(onPressed: () {
                        if(_createShelfKey.currentState!.validate()==false) return;
                        _shelfBloc.add(CreateShelfIn(shelfId: widget.shelfId,title: shelfCntrls['title']!.text,tags: shelfCntrls['tags']!.text.split(','),description: shelfCntrls['description']!.text,coverImage:null));
                      },style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll( Colors.green)),
                          child: const Text("Create",style: TextStyle(color: Colors.white),)),
                    ],)
                  ],)),
          ),
        ),
      );
    },);
  }
}
