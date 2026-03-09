import Flutter
import UIKit
import Firebase
import GoogleMobileAds

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1) Firebase initialization - crash-proof
    let info = Bundle.main.infoDictionary ?? [:]
    let disableFirebase = (info["FIREBASE_DISABLE_INIT"] as? String)?.lowercased() == "true"
    
    if disableFirebase {
      NSLog("[AppDelegate] Firebase initialization DISABLED via FIREBASE_DISABLE_INIT=true")
    } else {
      do {
        if let appId = info["FIREBASE_GOOGLE_APP_ID"] as? String, !appId.isEmpty,
           let apiKey = info["FIREBASE_API_KEY"] as? String, !apiKey.isEmpty,
           let projectId = info["FIREBASE_PROJECT_ID"] as? String, !projectId.isEmpty,
           let gcmSenderId = info["FIREBASE_GCM_SENDER_ID"] as? String, !gcmSenderId.isEmpty {
          let options = FirebaseOptions(googleAppID: appId, gcmSenderID: gcmSenderId)
          options.apiKey = apiKey
          options.projectID = projectId
          if let bucket = info["FIREBASE_STORAGE_BUCKET"] as? String { options.storageBucket = bucket }
          if let dbUrl = info["FIREBASE_DATABASE_URL"] as? String { options.databaseURL = dbUrl }
          
          if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
            NSLog("[AppDelegate] Firebase initialized via FirebaseOptions from Info.plist")
          } else {
            NSLog("[AppDelegate] Firebase already initialized")
          }
        } else if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  FileManager.default.fileExists(atPath: plistPath) {
          if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            NSLog("[AppDelegate] Firebase initialized via default GoogleService-Info.plist")
          }
        } else {
          NSLog("[AppDelegate] No Firebase config found; Dart-side will initialize Firebase")
        }
      }
    }
    
    // 2) Initialize Google Mobile Ads (safe - doesn't require Firebase)
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    // 3) Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
