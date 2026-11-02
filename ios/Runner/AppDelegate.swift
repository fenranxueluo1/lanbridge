import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

    if let registrar = self.registrar(forPlugin: "LanBridgeBackground") {
      let channel = FlutterMethodChannel(
        name: "lanbridge/background",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "notifyComplete":
          let args = call.arguments as? [String: Any]
          let content = UNMutableNotificationContent()
          content.title = (args?["title"] as? String) ?? "LANBridge"
          content.body = (args?["body"] as? String) ?? ""
          content.sound = .default
          let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
          )
          UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
              result(FlutterError(
                code: "NOTIFY_COMPLETE",
                message: error.localizedDescription,
                details: nil
              ))
            } else {
              result(nil)
            }
          }
        case "start", "stop":
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .sound])
  }
}
