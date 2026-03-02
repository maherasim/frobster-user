import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }

      GeneratedPluginRegistrant.register(with: self)
      GMSServices.provideAPIKey("AIzaSyABNz-zXkMtGvH1tpWyqJ6oAals5jpgOs0")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
