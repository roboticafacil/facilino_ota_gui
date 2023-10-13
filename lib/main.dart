import 'package:flutter/material.dart';
import 'PasswordRecovery.dart';
import 'Register.dart';
import 'SplashScreen.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'Login.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main(List<String> args) async {
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800,600),
    //fullScreen: true,
    minimumSize: Size(800,600),
    center: true,
    titleBarStyle: TitleBarStyle.normal,
    windowButtonVisibility: true,
    title: 'Facilino'
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    //await WindowManager.instance.maximize();
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Facilino',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      //home: const MyLoginPage(title: 'Login Page'),
      //home: const SplashScreen(),
      initialRoute: '/',
      navigatorKey: navigatorKey, // important,
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => SplashScreen(overwrite: false),
        // When navigating to the "/login" route, build the SecondScreen widget.
        '/login': (context) => LoginPage(alreadyLogged: false),
        '/already_logged_in': (context) => LoginPage(alreadyLogged: true),
        '/register': (context) => const RegistrationPage(),
        '/password_recovery': (context) => const PasswordRecoveryPage(),
      },
    );
  }
}


