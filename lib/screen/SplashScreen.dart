import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:mightyweb/utils/AppWidget.dart';
import 'package:nb_utils/nb_utils.dart'; // Utility for async storage
import '../utils/colors.dart';
import '../utils/constant.dart';
import 'DashboardScreen.dart';
import 'WalkThroughScreen1.dart';
import 'WalkThroughScreen2.dart';
import 'WalkThroughScreen3.dart';
import '../model/MainResponse.dart' as model1;
import 'HomeScreen.dart'; // HomeScreen for logged-in users

class SplashScreen extends StatefulWidget {
  static String tag = '/SplashScreen2';

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  List<model1.Walkthrough> mWalkList = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    // Decode walkthrough data from async storage
    Iterable mMenu = jsonDecode(getStringAsync(WALKTHROUGH));
    mWalkList =
        mMenu.map((model) => model1.Walkthrough.fromJson(model)).toList();

    // Check Firebase Authentication status
    var user = FirebaseAuth.instance.currentUser;

    // Add a small delay for splash screen effect
    await Future.delayed(Duration(seconds: 1));

    if (user != null) {
      // Navigate to HomeScreen if user is logged in
      Get.offAll(() => HomeScreen());
    } else {
      // If user is not logged in, proceed with the walkthrough or Dashboard
      if (getStringAsync(IS_WALKTHROUGH) == "true") {
        if (getBoolAsync(IS_FIRST_TIME, defaultValue: true)) {
          if (mWalkList.isNotEmpty) {
            if (getStringAsync(WALK_THROUGH_STYLE) == WALK_THROUGH_1)
              return WalkThroughScreen1().launch(context, isNewTask: true);
            else if (getStringAsync(WALK_THROUGH_STYLE) == WALK_THROUGH_2)
              return WalkThroughScreen2().launch(context, isNewTask: true);
            else
              return WalkThroughScreen3().launch(context, isNewTask: true);
          } else {
            DashBoardScreen().launch(context, isNewTask: true);
          }
        } else {
          DashBoardScreen().launch(context, isNewTask: true);
        }
      } else {
        DashBoardScreen().launch(context, isNewTask: true);
      }
    }
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getStringAsync(SPLASH_ENABLE_BACKGROUND) == "true"
          ? Stack(
              alignment: Alignment.center,
              children: [
                cachedImage(getStringAsync(SPLASH_BACKGROUND_URL),
                    fit: BoxFit.cover,
                    height: context.height(),
                    width: context.width()),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getStringAsync(SPLASH_ENABLE_LOGO).validate() != "false"
                        ? cachedImage(getStringAsync(SPLASH_LOGO_URL),
                                fit: BoxFit.cover, height: 120, width: 120)
                            .cornerRadiusWithClipRRect(10)
                        : SizedBox(),
                    4.height,
                    getStringAsync(SPLASH_ENABLE_TITLE) != "false"
                        ? Text(
                            getStringAsync(SPLASH_TITLE),
                            style: boldTextStyle(
                                size: 20,
                                color: getColorFromHex(
                                    getStringAsync(SPLASH_TITLE_COLOR),
                                    defaultColor: primaryColor1)),
                            textAlign: TextAlign.center,
                          ).paddingSymmetric(horizontal: 12)
                        : SizedBox(),
                  ],
                ).center(),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    getColorFromHex(getStringAsync(SPLASH_FIRST_COLOR),
                        defaultColor: primaryColor1),
                    getColorFromHex(getStringAsync(SPLASH_SECOND_COLOR),
                        defaultColor: primaryColor1),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  getStringAsync(SPLASH_ENABLE_LOGO) != "false"
                      ? cachedImage(getStringAsync(SPLASH_LOGO_URL),
                              fit: BoxFit.cover, height: 120, width: 120)
                          .cornerRadiusWithClipRRect(10)
                      : SizedBox(),
                  getStringAsync(SPLASH_ENABLE_TITLE) != "false"
                      ? Text(getStringAsync(SPLASH_TITLE),
                          style: boldTextStyle(
                              size: 20,
                              color: getColorFromHex(
                                  getStringAsync(SPLASH_TITLE_COLOR),
                                  defaultColor: primaryColor1)))
                      : SizedBox(),
                ],
              ).center(),
            ),
    );
  }
}
