import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shelf/routing/routes.dart';
import 'package:shelf/screens/HomeScreen.dart';
import 'package:shelf/screens/SplashScreen.dart';
import 'package:shelf/singletons/NotificationService.dart';
import 'package:shelf/singletons/persistance.dart';
import 'package:shelf/state/shelf/shelf_bloc.dart';

final parentNavKey=GlobalKey<NavigatorState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ShelfApp());
}

class ShelfApp extends StatefulWidget {
  const ShelfApp({super.key});

  @override
  State<ShelfApp> createState() => _ShelfAppState();
}

class _ShelfAppState extends State<ShelfApp> with WidgetsBindingObserver {
  static final _whiteListedRoutes = [];
  final router=GoRouter(
      debugLogDiagnostics: true,
      initialLocation: Routing.splash.path,
      routes: [
        GoRoute(
          name: Routing.splash.name,
          path: Routing.splash.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SplashScreen(title: "Splash"),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          name: Routing.home.name,
          path: Routing.home.path,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: const Homescreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          ),
        ),
      ]);

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);//lifecycycle events
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ShelfBloc>(lazy: false,create: (ctx) => ShelfBloc()),
      ],
      child:MaterialApp.router(
        key: parentNavKey,
        scaffoldMessengerKey: NotificationService.messengerKey,
        title: 'Spirtual Shakti',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.highContrastLight(primary: Color.fromRGBO(165, 62, 72, 1)),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
  }
}