import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}

/// The app's root view controller (Main.storyboard). On Live and Control held
/// sideways the app goes immersive (lib/core/system_ui.dart): the home
/// indicator dims, and a first swipe up from the bottom edge stays in the app,
/// so moving a stick near the edge does not leave it; a second swipe does.
class KDashViewController: FlutterViewController {
  private var immersive = false

  override var prefersHomeIndicatorAutoHidden: Bool { immersive }
  override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { immersive ? .bottom : [] }

  override func viewDidLoad() {
    super.viewDidLoad()
    FlutterMethodChannel(name: "com.koebelt.dash/system", binaryMessenger: binaryMessenger).setMethodCallHandler { [weak self] call, result in
      guard call.method == "setImmersive", let self else { return result(FlutterMethodNotImplemented) }
      self.immersive = (call.arguments as? Bool) ?? false
      self.setNeedsUpdateOfHomeIndicatorAutoHidden()
      self.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
      result(nil)
    }
  }
}
