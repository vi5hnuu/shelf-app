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

  @override
  void initState() {
    Persistance.initDB().then((_) => GoRouter.of(context).pushNamed(Routing.home.name));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(5),
                child: LottieBuilder.asset(
                  'assets/lottie/namaste.json',
                  fit: BoxFit.fill,
                ),
              ),
              Column(
                children: [
                  Text(
                    "Spiritual Shakti",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "PermanentMarker", fontSize: 32, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "initializing...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: "PermanentMarker", fontSize: 12, color: Theme.of(context).primaryColor),
                  )
                ],
              ),
            ],
          ),
        ));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
