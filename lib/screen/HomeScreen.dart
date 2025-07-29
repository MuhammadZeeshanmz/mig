import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  static String tag = '/HomeScreen';

  final String? mUrl, title;

  HomeScreen({this.mUrl, this.title});

  @override
  _HomeScreenState createState() => new _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;

  String? mInitialUrl;

  bool isWasConnectionLoss = false;
  bool mIsPermissionGrant = false;

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowFileAccessFromFileURLs: true,
      useOnDownloadStart: true,
      javaScriptCanOpenWindowsAutomatically: true,
      javaScriptEnabled: true,
      supportZoom: true,
      incognito: false,
    ),
    android: AndroidInAppWebViewOptions(useHybridComposition: true),
    ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true),
  );

  void _getInstanceId() async {
    await Firebase.initializeApp();
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Get the device token (for push notifications)
    String? token = await messaging.getToken();
    print("Firebase Token: $token");

    // Handling foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print("Notification Title: ${message.notification!.title}");
        print("Notification Body: ${message.notification!.body}");
      }
    });

    // Handling background notifications
    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      print("Background Notification: ${message.notification?.title}");
    });

    // Get initial message if app was opened from a notification
    FirebaseMessaging.instance.getInitialMessage();
  }

  @override
  void initState() {
    super.initState();
    _getInstanceId();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(color: Colors.blue, enabled: true),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
    init();
  }

  Future<void> init() async {
    mInitialUrl = widget.mUrl ?? "https://www.example.com";
    if (webViewController != null) {
      await webViewController!
          .loadUrl(urlRequest: URLRequest(url: Uri.parse(mInitialUrl!)));
    }
  }

  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          mIsPermissionGrant = true;
          setState(() {});
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _exitApp() async {
      if (await webViewController!.canGoBack()) {
        webViewController!.goBack();
        return false;
      } else {
        exit(0);
      }
    }

    Widget mLoadWeb() {
      return Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(mInitialUrl!)),
            initialOptions: options,
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              print("Loading started: $url");
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100) {
                pullToRefreshController!.endRefreshing();
              }
            },
            onLoadStop: (controller, url) async {
              print("Loading stopped: $url");
              pullToRefreshController!.endRefreshing();
            },
            onLoadError: (controller, url, code, message) {
              print("Load error: $message");
              pullToRefreshController!.endRefreshing();
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url;
              var url = navigationAction.request.url.toString();
              if (url.contains("http") || url.contains("https")) {
                return NavigationActionPolicy.ALLOW;
              } else {
                if (await canLaunch(url)) {
                  await launch(url);
                }
                return NavigationActionPolicy.CANCEL;
              }
            },
          ),
          Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "Home Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          ),
        ],
      ),
      body: SafeArea(child: mLoadWeb()),
    );
  }
}
