class FirebaseInAppMessaging {
  static final instance = FirebaseInAppMessaging();

  static var firebaseInAppMessagingInstance;

  void triggerEvent(String event) {
    print('In-App Messaging not supported on this platform');
  }
}
