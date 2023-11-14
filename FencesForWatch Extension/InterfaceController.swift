
import WatchKit
import Foundation
import CoreLocation
import UserNotifications
import WatchConnectivity
import Mailgun_In_Swift
class InterfaceController: WKInterfaceController, CLLocationManagerDelegate ,UNUserNotificationCenterDelegate,WCSessionDelegate{
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    
  }
    @IBOutlet var fenceTable: WKInterfaceTable!
    let mailgun = MailgunAPI(apiKey: "35ab0ac8fd5adf15df234f6d78db7dd3-c1fe131e-f82271e8", clientDomain: "sandbox5467681c112e420b820525b8e397d34c.mailgun.org")
  var fences: [FenceWatch] = []
  var session:WCSession?
  var flag = 0
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    flag = 1
    let radius = message["Radius"] as! Double
    let noteEntry = message["NoteEntry"]  as! String
    let noteExit = message["NoteExit"] as! String
    let latitude = message["Latitude"] as! Double
    let longitude = message["Longitude"] as! Double
    let fenceTitle = message["FenceTitle"] as! String
    let email = message["Email"] as! String
    let address = message["Address"] as! String
    let coordinate=CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude)
    let fence = FenceWatch.init(coordinate: coordinate, radius: radius,noteEntry: noteEntry, noteExit: noteExit,fenceTitle: fenceTitle,email: email,address: address)
    print("adress is :\(address)")
    for savedfences in fences{
      if (savedfences.fenceTitle == fence.fenceTitle){
          flag = 0
      }
    }
    if (flag == 1){
      fences.append(fence)
      saveFences()
    }
    updateRows()
    print("After Session Fences count =:\(fences.count)")
  }
    @IBAction func syncFences() {
        updateRows()
        print(fences.count)
    
    }
    
    @IBAction func removeFences() {
        fences.removeAll()
        saveFences()
        updateRows()
    }
    @IBAction func startFencing() {
        self.getLocation()
    }
  override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
    let fence = fences[rowIndex]
    presentController(withName: "Fence", context: fence)
  }
@IBAction func stopFencing() {
        locationManager.stopUpdatingLocation()
  }
  @IBOutlet var exitLabel: WKInterfaceLabel!
    @IBOutlet var radiusLabel: WKInterfaceLabel!
    @IBOutlet var entryLabel: WKInterfaceLabel!
  let locationManager = CLLocationManager()
  func loadFences() {
    fences.removeAll()
    let allFences = FenceWatch.allFences()
    allFences.forEach { fences.append($0)
    }
  }
  func saveFences() {
    let encoder = JSONEncoder()
    do {
      let data = try encoder.encode(fences)
      UserDefaults.standard.set(data, forKey: "savedItems")
           print("Saveing an elemnts")
      print(data.description)
    } catch {
      print("error encoding fences")
    }
  }
    func updateRows(){
        fenceTable.setNumberOfRows(fences.count, withRowType: "FenceRow")
        for index in 0..<fenceTable.numberOfRows {
            guard let controller = fenceTable.rowController(at: index) as? FenceRowController else { continue }
            
            controller.fence = fences[index]
        }
    }
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    loadFences()
    print(fences.count)
    if WCSession.isSupported() {    //  it is supported
      session = WCSession.default
      session!.delegate = self
      session!.activate()
    } else {
      print("Watch does not support WCSession")
    }
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.distanceFilter = 100
    locationManager.allowsBackgroundLocationUpdates = true
    updateRows()
  }
  func getLocation(){
    print("InterfaceController: \(NSDate())  - getLocation")
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.startUpdatingLocation()
    locationManager.distanceFilter = 100
    locationManager.allowsBackgroundLocationUpdates = true
  }
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    print("InterfaceController: \(NSDate())  - locationManager didUpdateLocations")
    guard let mostRecentLocation = locations.last else { return }
    let place = mostRecentLocation.coordinate
    print("\(place)")
    regionCompare(location: mostRecentLocation)
  }
  var alert:Int = 20
  var abc:Timer!
  func regionCompare(location:CLLocation){
    var distance:Double
    for fence in fences{
      let fenceLocation = CLLocation.init(latitude: fence.coordinate.latitude, longitude: fence.coordinate.longitude)
      distance=(location.distance(from: fenceLocation))
      print("Distance is:\(distance)m")
      print(fence.noteEntry)
      if (distance<fence.radius){
        alert = 20
        print("inside")
        handleEvent(fence: fence)
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.safeAlerts), userInfo: nil, repeats: false)
      }
      if(distance>fence.radius && distance<fence.radius+120){
        print("outside")
        alert = 10
        handleEvent(fence: fence)
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.calmAlerts), userInfo: nil, repeats: false)
        Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.calmAlerts), userInfo: nil, repeats: false)
        Timer.scheduledTimer(timeInterval: 90, target: self, selector: #selector(self.calmAlerts), userInfo: nil, repeats: false)
        Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(self.callAlert), userInfo: nil, repeats: false)
      }
    }
  }
  @objc func callAlert(){
    let phoneNumber = "tel://911"
    call(phoneNumber: phoneNumber)
  }
  @objc func safeAlerts(){
    
    if #available(watchOSApplicationExtension 3.0, *) {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
      }
      let content = UNMutableNotificationContent()
      content.title = NSString.localizedUserNotificationString(forKey: "Be calm!", arguments: nil)
      content.body = NSString.localizedUserNotificationString(forKey: "You are safe now!", arguments: nil)
      content.sound = UNNotificationSound.default()
      content.categoryIdentifier = "REMINDER_CATEGORY"
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
      let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
      print("Watch Notifications being called!")
      center.add(request ,withCompletionHandler: nil)
    }
  }
  @objc func calmAlerts(){
    if #available(watchOSApplicationExtension 3.0, *) {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
      }
      let content = UNMutableNotificationContent()
      content.title = NSString.localizedUserNotificationString(forKey: "Be Calm!", arguments: nil)
      content.body = NSString.localizedUserNotificationString(forKey: "You are going to be Alright.", arguments: nil)
      content.sound = UNNotificationSound.default()
      content.categoryIdentifier = "REMINDER_CATEGORY"
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
      let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
      print("Watch Notifications being called!")
      center.add(request ,withCompletionHandler: nil)
    }
  }
  func call(phoneNumber: String) {
    if let url = URL(string: phoneNumber) {
      if #available(iOS 10, *) {
        print("Calling 911")
        WKExtension.shared().openSystemURL(url)
      } else {
        let success = WKExtension.shared().openSystemURL(url)
        print("Calling 911")
        print("Open \(phoneNumber): \(success)")
      }
    }
  }
  func handleEvent(fence: FenceWatch){
    
    mailgun.sendEmail(to: fence.email, from: "Test User <test@Geofence.com>", subject: "patient is missing", bodyHTML: "<b>your patient is missing, The patient is currently at:<b>)") { mailgunResult in
      if mailgunResult.success{
        print("Email was sent")
        print("for fence:\(fence.fenceTitle)")
      }
      else{
        print("Fail")
      }
    }
 
    if #available(watchOSApplicationExtension 3.0, *) {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
      }
      let content = UNMutableNotificationContent()
      content.title = NSString.localizedUserNotificationString(forKey: "Alert!", arguments: nil)
      if alert==20{
      content.body = NSString.localizedUserNotificationString(forKey: fence.noteEntry, arguments: nil)
      }
      else if alert==10{
        content.body = NSString.localizedUserNotificationString(forKey: fence.noteExit, arguments: nil)
      }
      content.sound = UNNotificationSound.default()
      content.categoryIdentifier = "REMINDER_CATEGORY"
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
      let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
      print("Watch Notifications being called!")
      center.add(request ,withCompletionHandler: nil)
      print("Trying to sendEmail")
    // mail()
      print("email sending block passed")
    }
  }
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("InterfaceController: \(NSDate())  - locationManager didFailWithError")
    print("CL failed: \(error)")
  }
  override func willActivate() {
    super.willActivate()
    loadFences()
  }
  
  override func didDeactivate() {
    super.didDeactivate()
  }
  
}
