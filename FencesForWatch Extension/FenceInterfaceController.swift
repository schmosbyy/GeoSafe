
import WatchKit
import Foundation
import CoreLocation

class FenceInterfaceController: WKInterfaceController,CLLocationManagerDelegate {
  @IBOutlet var addressLabel: WKInterfaceLabel!
  @IBOutlet var titleLabel: WKInterfaceLabel!
  @IBOutlet var radiusLabel: WKInterfaceLabel!
  @IBOutlet var noteEntryLabel: WKInterfaceLabel!
  @IBOutlet var noteExitLabel: WKInterfaceLabel!
    @IBOutlet var emailLabel: WKInterfaceLabel!
    var address: String!
  var fence: FenceWatch? {
    didSet {
      guard let fence = fence else { return }
      titleLabel.setText("\(fence.fenceTitle)")
      radiusLabel.setText("\(String(fence.radius))m")
      noteEntryLabel.setText("Entry:\(fence.noteEntry)")
      noteExitLabel.setText("Exit:\(fence.noteExit)")
      addressLabel.setText("Address:\(fence.address)")
      emailLabel.setText("Email:\(fence.email)")
      
    }
  }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
      if let fence = context as? FenceWatch {
        self.fence = fence
      }
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
