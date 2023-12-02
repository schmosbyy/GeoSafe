

import UIKit
import MapKit
import CoreLocation
import UserNotifications
import WatchConnectivity
struct PreferencesKeys {
  static let savedItems = "savedItems"
}
class FencesVC: UIViewController,WCSessionDelegate{
  func sessionDidBecomeInactive(_ session: WCSession) {
    //
  }
  
  func sessionDidDeactivate(_ session: WCSession) {
    //
  }
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    //
  }
  var session:WCSession?
 @IBAction func shareLocation(_ sender: Any) {
    let vc = GeoSafe.SecondVC()
    let activityViewController = UIActivityViewController(activityItems: vc.activityItems(latitude: shareCoordinates.latitude, longitude: shareCoordinates.longitude)!, applicationActivities: nil)
    present(activityViewController, animated: true, completion: nil)
  }
  var shareCoordinates = CLLocationCoordinate2D()
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let mostRecentLocation = locations.last else { return }
    shareCoordinates = mostRecentLocation.coordinate
    let region = MKCoordinateRegionMakeWithDistance(mostRecentLocation.coordinate, 500, 500)
    mapView.setRegion(region, animated: true)
        
        // Optionally, you can add a pin for the current location
    let annotation = MKPointAnnotation()
    annotation.coordinate = mostRecentLocation.coordinate
    mapView.addAnnotation(annotation)
  }
 @IBOutlet var mapView: MKMapView!
    var fences: [Fence] = []
  let locationManager = CLLocationManager()
 override func viewDidLoad() {
    super.viewDidLoad()
    if WCSession.isSupported() {  
      session = WCSession.default
      session!.delegate = self
      session!.activate()
    } else {
      
      print("iPhone does not support WCSession")
    }
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.startUpdatingLocation()
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = 50
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = true
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .follow
    loadFences()
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "addFence" {
      let navigationController = segue.destination as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddFences
      vc.delegate = self
    }
  }
  
  // MARK: Loading and saving functions
  func loadFences() {
    fences.removeAll()
    let allFences = Fence.allFences()
    allFences.forEach { add($0) }
  }
  
  func saveFences() {
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(fences)
      UserDefaults.standard.set(data, forKey: PreferencesKeys.savedItems)
    } catch {
      print("error encoding fences")
    }
  }
  var flagTitle = 0
  var flagEmail = 0
  var flagRadius = 0
  func add(_ fence: Fence) {
    flagTitle = 1
    flagEmail = 1
    flagRadius = 1
    for fencesSaved in fences
    {
      if (fence.fenceTitle == fencesSaved.fenceTitle){
        flagTitle = 0
      }
    }
    if (fence.email.isEmail()){
      flagEmail = 1 //email is valid
    }
    else{
        flagEmail = 0
    }
    if (fence.radius > 99){
      flagRadius = 1
    }else{
      flagRadius = 0
    }
    if ((flagTitle == 1) && (flagEmail == 1)&&(flagRadius == 1)){
        fences.append(fence)
        mapView.addAnnotation(fence)
        addRadiusOverlay(forFence: fence)
        updateFencesCount()
    }
    else if(flagTitle == 0 ){
      let alert = UIAlertController(title: "Try Again!", message: "Fence Name not Unique!", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title:"Ok",style:UIAlertActionStyle.default, handler: {(action) in
        alert.dismiss(animated: true, completion: nil)
      }))
      self.present(alert, animated: true, completion: nil)
    }
    else if(flagEmail == 0 ){
      let alert = UIAlertController(title: "Try Again!", message: "Email not valid!", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title:"Ok",style:UIAlertActionStyle.default, handler: {(action) in
        alert.dismiss(animated: true, completion: nil)
      }))
      self.present(alert, animated: true, completion: nil)
    }
    else if(flagRadius == 0){
      let alert = UIAlertController(title: "Try Again!", message: "Radius Should be more than 100m", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title:"Ok",style:UIAlertActionStyle.default, handler: {(action) in
        alert.dismiss(animated: true, completion: nil)
      }))
      self.present(alert, animated: true, completion: nil)
    }
    else if((flagTitle == 0) && (flagEmail == 0)){
      let alert = UIAlertController(title: "Try Again!", message: "Invalid Data!", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title:"Ok",style:UIAlertActionStyle.default, handler: {(action) in
        alert.dismiss(animated: true, completion: nil)
      }))
      self.present(alert, animated: true, completion: nil)
    }
  }
  
  func remove(_ fence: Fence) {
    guard let index = fences.index(of: fence) else { return }
    fences.remove(at: index)
    mapView.removeAnnotation(fence)
    removeRadiusOverlay(forFences: fence)
    updateFencesCount()
  }
  func updateFencesCount() {
    title = "Fences: \(fences.count)"
    navigationItem.rightBarButtonItem?.isEnabled = (fences.count < 20)
  }
  
  // MARK: Map overlay functions
  func addRadiusOverlay(forFence fence: Fence) {
    mapView?.add(MKCircle(center: fence.coordinate, radius: fence.radius))
  }
  
  func removeRadiusOverlay(forFences fence: Fence) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    guard let overlays = mapView?.overlays else { return }
    for overlay in overlays {
      guard let circleOverlay = overlay as? MKCircle else { continue }
      let coord = circleOverlay.coordinate
      if coord.latitude == fence.coordinate.latitude && coord.longitude == fence.coordinate.longitude && circleOverlay.radius == fence.radius {
        mapView?.remove(circleOverlay)
        break
      }
    }
  }
    @IBAction func syncFences(_ sender: Any) {
      let allFences = Fence.allFences()
      print("allFences: ",allFences.isEmpty)
      if allFences.isEmpty{
        let message : [String : AnyObject]
        message = [
            "FenceTitle":"NoFenceFound"
        ] as [String : AnyObject]
        session!.sendMessage(message, replyHandler: nil, errorHandler: nil)
      }else{
        for fence in allFences{
          if session!.isReachable {     // it is reachable
                let message : [String : AnyObject]
                message = [
                    "FenceTitle":fence.fenceTitle,
                    "NoteEntry":fence.noteEntry,
                    "NoteExit":fence.noteExit,
                    "Radius":fence.radius,
                    "Latitude":fence.coordinate.latitude,
                    "Longitude":fence.coordinate.longitude,
                    "Email":fence.email,
                    "Address":fence.address,
                    ] as [String : AnyObject]
                session!.sendMessage(message, replyHandler: nil, errorHandler: nil)
                print("Watch send gesture ")
            } else{
                print("WCSession is not reachable") //it is not reachable
            }
          }
        }
    }
  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    mapView.zoomToUserLocation()
  }
  
  func region(with fence: Fence) -> CLCircularRegion {
    let region = CLCircularRegion(center: fence.coordinate, radius: fence.radius, identifier: fence.identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    return region
  }
  
  func startMonitoring(fence: Fence) {
    if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
      showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
      return
    }
    
    if CLLocationManager.authorizationStatus() != .authorizedAlways {
      let message = """
      Your geotification is saved but will only be activated once you grant
      GEOFENCING permission to access the device location.
      """
      showAlert(withTitle:"Warning", message: message)
    }
    
    let fenceRegion = region(with: fence)
    locationManager.startMonitoring(for: fenceRegion)
  }
  
  func stopMonitoring(fence: Fence) {
    for region in locationManager.monitoredRegions {
      guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == fence.identifier else { continue }
      locationManager.stopMonitoring(for: circularRegion)
    }
  }
}

// MARK: AddGeotificationViewControllerDelegate
extension FencesVC: AddFencesDelegate {
  
  func addFence(_ controller: AddFences, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, noteEntry: String,noteExit: String,fenceTitle: String,email: String,address: String){
    controller.dismiss(animated: true, completion: nil)
    let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
    let fence = Fence(coordinate: coordinate, radius: clampedRadius, identifier: identifier, noteEntry: noteEntry,noteExit:noteExit,fenceTitle:fenceTitle,email: email,address: address)
    add(fence)
    startMonitoring(fence: fence)
    saveFences()
  }
  
}

// MARK: - Location Manager Delegate
extension FencesVC: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = status == .authorizedAlways
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    print("Monitoring failed for region with identifier: \(region!.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location Manager failed with the following error: \(error)")
  }
  
}

// MARK: - MapView Delegate
extension FencesVC: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "myFence"
    if annotation is Fence {
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        let removeButton = UIButton(type: .custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(named: "DeleteGeotification")!, for: .normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }
  
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: overlay)
      circleRenderer.lineWidth = 1.0
      circleRenderer.strokeColor = .blue
      circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
      return circleRenderer
    }
    return MKOverlayRenderer(overlay: overlay)
  }
  
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    let fence = view.annotation as! Fence
    remove(fence)
    saveFences()
  }
  
}
