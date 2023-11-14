

import UIKit
import MapKit

protocol AddFencesDelegate {
  func addFence(_ controller: AddFences, didAddCoordinate coordinate: CLLocationCoordinate2D,
                radius: Double, identifier: String, noteEntry: String, noteExit: String, fenceTitle:String, email: String,address: String)
}

class AddFences: UITableViewController {
  
  @IBOutlet weak var emailAdr: UITextField!
  @IBOutlet var addButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!
  @IBOutlet weak var fenceTitle: UITextField!
  @IBOutlet weak var radiusTextField: UITextField!
  @IBOutlet weak var noteTextField: UITextField!
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var noteExitField: UITextField!
  
  var delegate: AddFencesDelegate?
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItems = [addButton, zoomButton]
    addButton.isEnabled = false
  }
  @IBAction func textFieldEditingChanged(sender: UITextField) {
    addButton.isEnabled = !radiusTextField.text!.isEmpty && !noteTextField.text!.isEmpty && !noteExitField.text!.isEmpty && !fenceTitle.text!.isEmpty
  }
  @IBAction func onCancel(sender: AnyObject) {
    dismiss(animated: true, completion: nil)
  }
  var address: String = ""
  @IBAction private func onAdd(sender: AnyObject) {
    
    let coordinate = mapView.centerCoordinate
    let radius = Double(radiusTextField.text!) ?? 0
    let identifier = NSUUID().uuidString
    let noteEntry = noteTextField.text
    let noteExit = noteExitField.text
    let title = fenceTitle.text
    let email = emailAdr.text
    let location = CLLocation.init(latitude: (coordinate.latitude), longitude: coordinate.longitude)
    getLocationAddress(loc: location){
      genre in
      self.delegate?.addFence(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, noteEntry: noteEntry!,noteExit: noteExit!,fenceTitle: title!, email: email!, address: genre)
    }
  }
  var placemark: CLPlacemark!
  func getLocationAddress(loc: CLLocation,callback: @escaping (String) -> ()) {//}-> String{
    let ceo = CLGeocoder()
    var newString :String = ""
    ceo.reverseGeocodeLocation(loc, completionHandler:
      {(placemarks, error) in
        if (error != nil)
        {
          
          print("reverse geodcode fail: \(error!.localizedDescription)")
        }
        if (placemarks?.count)! > 0 {
          self.placemark = placemarks![0]
          if self.placemark.subThoroughfare != nil {
            newString = self.placemark.subThoroughfare! + " "
          }
          if self.placemark.thoroughfare != nil {
            newString = newString + self.placemark.thoroughfare! + ", "
          }
          if self.placemark.postalCode != nil {
            newString = newString + self.placemark.postalCode! + " "
          }
          if self.placemark.locality != nil {
            newString = newString + self.placemark.locality! + ", "
          }
          if self.placemark.administrativeArea != nil {
            newString = newString + self.placemark.administrativeArea! + " "
          }
          if self.placemark.country != nil {
            newString = newString + self.placemark.country!
          }
          callback(newString)
        }
    })
  }
  @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
    mapView.zoomToUserLocation()
  }
}
