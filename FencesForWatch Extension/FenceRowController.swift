
import WatchKit

class FenceRowController: NSObject {
  @IBOutlet var titleLabel: WKInterfaceLabel!
  @IBOutlet var  radiusLabel: WKInterfaceLabel!
  
  var fence: FenceWatch? {
    // 2
    didSet {
      // 3
      guard let fence = fence else { return }
      // 4
      titleLabel.setText(fence.fenceTitle)
      radiusLabel.setText("\(String(fence.radius))m")
      // 5
    }
  }
}
