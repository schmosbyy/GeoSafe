

import UIKit
import CoreLocation
import UserNotifications
var triggerAlert: Bool!
var countAlert: Int!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate,UNUserNotificationCenterDelegate {
  
  var window: UIWindow?
  let locationManager = CLLocationManager()
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = 5
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = true
    let options: UNAuthorizationOptions = [.badge, .sound, .alert]
    UNUserNotificationCenter.current()
      .requestAuthorization(options: options) { success, error in
        if let error = error {
          print("Error: \(error)")
        }
    }
    return true
  }
 
  func applicationDidBecomeActive(_ application: UIApplication) {
    application.applicationIconBadgeNumber = 0
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
  }
 func handleEvent(for region: CLRegion!){
    if UIApplication.shared.applicationState == .active {
      guard let message = note(from: region.identifier) else { return }
      window?.rootViewController?.showAlert(withTitle: nil, message: message)
    } else {
      guard let body = note(from: region.identifier) else { return }
      let notificationContent = UNMutableNotificationContent()
      notificationContent.title = "Alarm"
      notificationContent.body = body
      notificationContent.sound = UNNotificationSound.default()
      notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
      let request = UNNotificationRequest(identifier: "alarm",
                                          content: notificationContent,
                                          trigger: trigger)
      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          print("Error: \(error)")
        }
      }
  }
  }/*
  func setCategories(){
    let snoozeAction = UNNotificationAction(identifier: "snooze", title: "Snooze 5 Sec", options: [.authenticationRequired])
    let commentAction = UNTextInputNotificationAction(identifier: "comment", title: "Add Comment", options: [], textInputButtonTitle: "Add", textInputPlaceholder: "Add Comment Here")
    let alarmCategory = UNNotificationCategory(identifier: "alarm.category",actions: [snoozeAction,commentAction],intentIdentifiers: [], options: [])
    UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
  }
 */
  func call(phoneNumber: String) {
    if let url = URL(string: phoneNumber) {
      if #available(iOS 10, *) {
        UIApplication.shared.open(url, options: [:],
                                  completionHandler: {
                                    (success) in
                                    print("Open \(phoneNumber): \(success)")
        })
      } else {
        let success = UIApplication.shared.openURL(url)
        print("Open \(phoneNumber): \(success)")
      }
    }
  }
  func note(from identifier: String) -> String? {
    let fences = Fence.allFences()
    guard let matched = fences.filter({
      $0.identifier == identifier
    }).first else { return nil }
    if   (alert==10)
    {
      return matched.noteEntry
    }else{
      return matched.noteExit     //If Errors Try .note
    }
  }
  var alert = 10
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLCircularRegion {
      alert = 10
      handleEvent(for: region)
      let phoneNumber = "tel://991"
      call(phoneNumber: phoneNumber)
      print("EnterRegion getting called")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region is CLCircularRegion {
      alert = 20
      handleEvent(for: region)
      let phoneNumber = "tel://011"
      call(phoneNumber: phoneNumber)
      print("ExitRegion Getting Called")
    }
  }
}
/*
  notificationContent.categoryIdentifier = "alarm.category"
 //old identifier "location_change"(new is alarm"
 alert = 10 in enter
 alert =20 in exit
 put this in did enter and did exit
 let phoneNumber = "tel://991"
call(phoneNumber: phoneNumber)
*/
