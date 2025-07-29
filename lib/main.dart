import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mightyweb/firebase_options.dart';
import 'package:mightyweb/screen/HomeScreen.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'AppTheme.dart';
import 'app_localizations.dart';
import 'model/LanguageModel.dart';
import 'screen/login_view.dart';
import 'screen/signup_view.dart';
import 'utils/common.dart';
import 'utils/constant.dart';
import 'component/NoInternetConnection.dart';
import 'store/AppStore.dart';

AppStore appStore = AppStore();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  HttpOverrides.global = HttpOverridesSkipCertificate();
  await initialize();

  appStore.setDarkMode(aIsDarkMode: getBoolAsync(isDarkModeOnPref));
  appStore.setLanguage(getStringAsync(APP_LANGUAGE, defaultValue: 'en'));

  if (isMobile) {
    MobileAds.instance.initialize();
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);
    OneSignal.consentRequired(false);
    OneSignal.initialize(getStringAsync(ONESINGLE, defaultValue: mOneSignalID));
    OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('NOTIFICATION: ${event.notification.jsonRepresentation()}');
      event.preventDefault();
      event.notification.display();
    });
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    setStatusBarColor(appStore.primaryColors,
        statusBarBrightness: Brightness.light);

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) async {
      appStore.setConnectionState(result);
      if (result == ConnectivityResult.none) {
        log('❌ No Internet');
        push(NoInternetConnection());
      } else {
        pop(); // remove "no internet" screen
        log('✅ Connected');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        locale: Locale(getStringAsync(APP_LANGUAGE, defaultValue: 'en')),
        supportedLocales: Language.languagesLocale(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) => locale,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appStore.isDarkModeOn! ? ThemeMode.dark : ThemeMode.light,
        scrollBehavior: SBehavior(),
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const CustomLoginScreen(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) => HomeScreen(
                mUrl: "https://www.example.com",
                title: "Web App",
              ),
        },
        home: StartUpWrapper(),
      );
    });
  }
}

/// ✅ Checks both internet and auth status
class StartUpWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (!appStore.isNetworkAvailable) {
        return NoInternetConnection();
      } else {
        return AuthCheck();
      }
    });
  }
}

/// ✅ Navigates based on FirebaseAuth user status
class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return HomeScreen(
            mUrl: "https://www.example.com",
            title: "Web App",
          );
        } else {
          return const CustomLoginScreen();
        }
      },
    );
  }
}
