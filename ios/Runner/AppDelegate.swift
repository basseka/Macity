import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  // L'APNs token peut arriver AVANT que Firebase (initialise cote Dart) soit
  // pret. On le met en cache et on l'applique des que FirebaseApp.app() existe,
  // sinon il est perdu et getToken() reste null indefiniment (bug : 0 token iOS).
  private var pendingApnsToken: Data?

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

    // Son des stories (Map Live) : sans configurer l'AVAudioSession, video_player
    // ne joue PAS le son quand l'iPhone est en mode silencieux. On passe la session
    // en .playback -> le son ignore l'interrupteur silencieux (le volume est demande
    // cote Dart via setVolume(1.0), commit dbd8017).
    // .mixWithOthers : setActive(true) au lancement n'interrompt PAS la musique /
    // podcast deja en cours chez l'utilisateur (sinon, .playback seul couperait son
    // audio des l'ouverture de l'app, avant meme qu'une story joue). Le son des
    // stories se superpose au lieu de tout couper.
    // NB : configurer la session ne DECLENCHE aucune lecture, et aucun mode audio en
    // arriere-plan n'est declare (UIBackgroundModes) -> pas de lecture background non
    // desiree. Retirer .mixWithOthers si l'on veut que la story prenne le dessus.
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, options: [.mixWithOthers])
      try session.setActive(true)
    } catch {
      NSLog("[AVAudioSession] config .playback echouee: \(error.localizedDescription)")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Transmet le token APNs a Firebase. Si Firebase n'est pas encore configure
  // (init cote Dart pas terminee), on met le token en cache et on reessaie
  // jusqu'a ce que FirebaseApp.app() existe.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    pendingApnsToken = deviceToken
    applyApnsTokenWhenReady()
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[APNs] echec enregistrement: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Applique l'APNs token des que Firebase est pret. Retente toutes les 0.3s
  // (max ~12s) pour absorber la race init Firebase (Dart) vs callback APNs.
  private func applyApnsTokenWhenReady(attempt: Int = 0) {
    guard let token = pendingApnsToken else { return }
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = token
      pendingApnsToken = nil
      return
    }
    if attempt >= 40 { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      self?.applyApnsTokenWhenReady(attempt: attempt + 1)
    }
  }
}
