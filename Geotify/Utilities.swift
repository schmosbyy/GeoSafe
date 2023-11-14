

import UIKit
import MapKit

// MARK: Helper Extensions
extension UIViewController {
  func showAlert(withTitle title: String?, message: String?) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alert.addAction(action)
    present(alert, animated: true, completion: nil)
  }
}

extension MKMapView {
  func zoomToUserLocation() {
    guard let coordinate = userLocation.location?.coordinate else { return }
    let region = MKCoordinateRegionMakeWithDistance(coordinate, 600, 600)
    setRegion(region, animated: true)
  }
}
let __firstpart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)

extension String {
  func isEmail() -> Bool {
    return __emailPredicate.evaluate(with: self)
  }
}

extension UITextField {
  func isEmail() -> Bool {
    return self.text!.isEmail()
  }
}
