import Flutter
import UIKit

public class SwiftNativeVideoViewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let nativeVideoViewFactory = NativeVideoViewFactory(registrar: registrar)
    registrar.register(nativeVideoViewFactory, withId: "native_video_view")
  }
}
