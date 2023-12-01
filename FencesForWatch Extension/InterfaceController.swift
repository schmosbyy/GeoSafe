
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
    let mailgun = MailgunAPI(apiKey: "2d7691b4ba7eab24437f4bb963f523e3-5d2b1caa-9b6f1109", clientDomain: "sandbox238cdc08105048408942c6b1d34f21ba.mailgun.org")
  var fences: [FenceWatch] = []
  var session:WCSession?
  var flag = 0
  var inFence:Bool = true
  var isFunctionAllowed:Bool = true
  var timer: Timer?
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
    print("fences count :",fences.count)
    if WCSession.isSupported() {    //  it is supported
      session = WCSession.default
      session!.delegate = self
      session!.activate()
    } else {
      print("Watch does not support WCSession")
    }
    updateRows()
  }
  func getLocation(){
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.requestWhenInUseAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.distanceFilter = 100
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.startUpdatingLocation()
  }
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let mostRecentLocation = locations.last else { return }
    let place = mostRecentLocation.coordinate
    regionCompare(location: mostRecentLocation)
  }

  func regionCompare(location:CLLocation){
    var distance:Double
    var address:String = ""
    for fence in fences{
      let fenceLocation = CLLocation.init(latitude: fence.coordinate.latitude, longitude: fence.coordinate.longitude)
      distance=(location.distance(from: fenceLocation))
      address = "Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)"
      if (distance<fence.radius){
        inFence = true
        handleEvent(fence: fence,location: address,inFence: inFence)
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.safeAlerts), userInfo: nil, repeats: false)
      }
      if(distance>fence.radius && distance<fence.radius+500){
        inFence = false
        handleEvent(fence: fence,location: address,inFence: inFence)
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.calmAlerts), userInfo: nil, repeats: false)
        Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.calmAlerts), userInfo: nil, repeats: false)
        Timer.scheduledTimer(timeInterval: 90, target: self, selector: #selector(self.calmAlerts), userInfo: nil, repeats: false)
        
      }
    }
  }
  @objc func safeAlerts(){
    triggerWatchAlert(title: NSString.localizedUserNotificationString(forKey: "Be Calm!", arguments: nil),message: NSString.localizedUserNotificationString(forKey: "You are safe now", arguments: nil))
  }
  @objc func calmAlerts(){
    triggerWatchAlert(title: NSString.localizedUserNotificationString(forKey: "Be Calm!", arguments: nil),message: NSString.localizedUserNotificationString(forKey: "You are going to be Alright.", arguments: nil))
  }
  

  @objc func enableFunction() {
          // Re-enable the function after the cooldown period
          isFunctionAllowed = true
          print("Function is now allowed.")
      }
  func handleEvent(fence: FenceWatch,location: String,inFence:Bool){
    // Check if the function is allowed to execute
    guard isFunctionAllowed else {
        print("Function is blocked. Wait for the cooldown period.")
        return
    }
    isFunctionAllowed = false
    print("Sending EMail: address = "+location)
    mailgun.sendEmail(to: fence.email, from: "Test User <test@Geofence.com>", subject: "patient is missing", bodyHTML: "<b>your patient is missing, The patient is currently at:<b>\(location)</b>)") { [self] mailgunResult in
      if mailgunResult.success{
        print("Email sent for fence:\(fence.fenceTitle)")
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.enableFunction), userInfo: nil, repeats: false)
      }
      else{
        print("Fail")
      }
    }
    if inFence{
      triggerWatchAlert(title: NSString.localizedUserNotificationString(forKey: "Alert!", arguments: nil),message: fence.noteEntry)
    }else{
      triggerWatchAlert(title: NSString.localizedUserNotificationString(forKey: "Alert!", arguments: nil),message: fence.noteExit)
    }
  }
  func triggerWatchAlert(title: String, message: String){
    if #available(watchOSApplicationExtension 3.0, *) {
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
      }
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = message
      content.sound = UNNotificationSound.default()
      content.categoryIdentifier = "REMINDER_CATEGORY"
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
      let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
      center.add(request ,withCompletionHandler: nil)
      print("Watch Notifications being called! and email sent : alert message :"+message)
    }
  }
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    //print("CL failed: \(error)")
  }
  override func willActivate() {
    super.willActivate()
    loadFences()
  }
  override func didDeactivate() {
    super.didDeactivate()
  }
}
