import 'dart:async';

import 'package:bhakti_bhoomi/routing/routes.dart';
import 'package:bhakti_bhoomi/state/auth/auth_bloc.dart';
import 'package:bhakti_bhoomi/state/httpStates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

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
    timer=Timer(const Duration(seconds: 3), () {
      final state=BlocProvider.of<AuthBloc>(context).state;
      handleTryAuth(state);
    });
    BlocProvider.of<AuthBloc>(context).add(const TryAuthenticatingEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) =>handleTryAuth(state),
      listenWhen: (previous, current) => previous != current,
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) => Scaffold(
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
      )),
    );
  }

  handleTryAuth(final AuthState state){
    print("time ${timer?.isActive}, isLoading : ${state.isLoading(forr: Httpstates.TRY_AUTH)}, isError : ${state.isError(forr: Httpstates.TRY_AUTH)}, authenticated : ${state.isAuthtenticated && timer?.isActive!=true}");
    if (state.isLoading(forr: Httpstates.TRY_AUTH) || timer?.isActive==true){
      return;
    }else if(state.isError(forr: Httpstates.TRY_AUTH) || (!state.isAuthtenticated && timer?.isActive==false)){
      GoRouter.of(context).replaceNamed(Routing.login.name);
    }else if(state.isAuthtenticated && timer?.isActive!=true){
      GoRouter.of(context).replaceNamed(Routing.home.name);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
