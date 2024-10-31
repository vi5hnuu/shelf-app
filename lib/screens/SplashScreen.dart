import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shelf/routing/routes.dart';
import 'package:shelf/singletons/persistance.dart';

class SplashScreen extends StatefulWidget {
  final String title;
  const SplashScreen({super.key, required this.title});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;
  String? error;

  @override
  void initState() {
    timer=Timer(const Duration(seconds: 3),(){
      if(Persistance().db==null) return;
      goToHome();
    });

    Persistance.initDB().then((_){
      if(timer!.isActive) return;
      goToHome();
    }).catchError((e){setState(()=>error=e.message);});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 75,vertical: 125),
              child: LottieBuilder.asset(
                'assets/lottie/shelf.json',
                fit: BoxFit.fitWidth,
              ),
            ),
            Column(
              children: [
                Text(
                  "Shelf",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: "PermanentMarker", fontSize: 32, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 15),
                Text(
                  error ?? "Initializing...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: "PermanentMarker", fontSize: 18, color: Theme.of(context).primaryColor.withOpacity(0.5)),
                )
              ],
            ),
          ],
        ));
  }

  goToHome(){
    GoRouter.of(context).replaceNamed(Routing.home.name);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
