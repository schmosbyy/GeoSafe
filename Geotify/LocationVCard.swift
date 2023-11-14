
import Foundation
import CoreLocation
import UIKit
import MobileCoreServices
class SecondVC: UIViewController{
  func activityItems(latitude: Double, longitude: Double) -> [AnyObject]? {
    var items = [AnyObject]()
    
    let locationTitle = "Shared Location"
    let URLString = "https://maps.apple.com?ll=\(latitude),\(longitude)"
    
    if let url = NSURL(string: URLString) {
      items.append(url)
    }
    
    let locationVCardString = [
      "BEGIN:VCARD",
      "VERSION:3.0",
      "N:;\(locationTitle);;;",
      "FN:\(locationTitle)",
      "item1.URL;type=pref:\(URLString)",
      "item1.X-ABLabel:map url",
      "END:VCARD"
      ].joined(separator: "\n")
    
    guard let vCardData = locationVCardString.data(using: String.Encoding.utf8) else {
      return nil
    }
    
    let vCardActivity = NSItemProvider(item: vCardData as NSSecureCoding, typeIdentifier: kUTTypeVCard as CFString as String)
    
    items.append(vCardActivity)
    
    items.append(locationTitle as AnyObject)
    
    return items
  }
}

