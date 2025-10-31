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
    // Initialize Firebase via FirebaseOptions from Info.plist
    let info = Bundle.main.infoDictionary ?? [:]
    let disableFirebase = (info["FIREBASE_DISABLE_INIT"] as? String)?.lowercased() == "true"
    if disableFirebase {
      NSLog("[AppDelegate] Firebase initialization DISABLED via FIREBASE_DISABLE_INIT=true")
    } else {
      if let appId = info["FIREBASE_GOOGLE_APP_ID"] as? String, !appId.isEmpty,
         let apiKey = info["FIREBASE_API_KEY"] as? String, !apiKey.isEmpty,
         let projectId = info["FIREBASE_PROJECT_ID"] as? String, !projectId.isEmpty,
         let gcmSenderId = info["FIREBASE_GCM_SENDER_ID"] as? String, !gcmSenderId.isEmpty {
        let options = FirebaseOptions(googleAppID: appId, gcmSenderID: gcmSenderId)
        options.apiKey = apiKey
        options.projectID = projectId
        if let bucket = info["FIREBASE_STORAGE_BUCKET"] as? String { options.storageBucket = bucket }
        if let dbUrl = info["FIREBASE_DATABASE_URL"] as? String { options.databaseURL = dbUrl }
        FirebaseApp.configure(options: options)
        NSLog("[AppDelegate] Firebase initialized via FirebaseOptions")
      } else {
        // Fallback: try default configure (requires GoogleService-Info.plist in bundle)
        if let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           FileManager.default.fileExists(atPath: plistPath) {
          FirebaseApp.configure()
          NSLog("[AppDelegate] Firebase initialized via default GoogleService-Info.plist")
        } else {
          NSLog("[AppDelegate] GoogleService-Info.plist NOT found; skipping Firebase initialization to avoid crash")
        }
      }
    }
    
    // Initialize Google Mobile Ads
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
