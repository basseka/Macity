import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NE PAS appeler FirebaseApp.configure() ici : sans GoogleService-Info.plist,
    // cet appel natif crashe l'app au lancement (rejet App Store 2.1(a)).
    // Firebase est initialise cote Dart via DefaultFirebaseOptions (firebase_options.dart),
    // qui n'a pas besoin du fichier .plist.

    // Enregistrement APNs pour les push notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Transmet le token APNs a Firebase (seulement si Firebase est deja configure,
  // pour eviter tout crash si le token arrive avant l'init Dart).
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = deviceToken
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
