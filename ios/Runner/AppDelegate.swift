import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Keep every Fusion window out of screenshots and screen recordings.
    NotificationCenter.default.addObserver(
      forName: UIWindow.didBecomeKeyNotification,
      object: nil,
      queue: .main
    ) { note in
      (note.object as? UIWindow)?.hideFromScreenCapture()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

extension UIWindow {
  private static let captureShieldTag = 0x5EC0

  /// iOS has no API to block screenshots, but it leaves the contents of a
  /// secure text field out of screenshots and screen recordings. Moving the
  /// window's layer under such a field's layer hides the whole app from them.
  /// Only layers move; views (and so touches) stay where they were.
  func hideFromScreenCapture(retries: Int = 5) {
    if viewWithTag(Self.captureShieldTag) != nil { return }
    guard let host = layer.superlayer else {
      // Not on screen yet: try again on the next run loop pass.
      if retries > 0 {
        DispatchQueue.main.async { [weak self] in
          self?.hideFromScreenCapture(retries: retries - 1)
        }
      }
      return
    }
    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    field.tag = Self.captureShieldTag
    addSubview(field)
    host.addSublayer(field.layer)
    let canvas: CALayer?
    if #available(iOS 17.0, *) {
      canvas = field.layer.sublayers?.last
    } else {
      canvas = field.layer.sublayers?.first
    }
    canvas?.addSublayer(layer)
  }
}
