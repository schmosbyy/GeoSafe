

import UIKit
import MapKit
import CoreLocation

class FenceWatch: NSObject, Codable, MKAnnotation {
  
  
  enum CodingKeys: String, CodingKey {
    case latitude, longitude, radius, noteEntry,noteExit,fenceTitle,email,address//identifier,
  }
  var coordinate: CLLocationCoordinate2D
  var radius: CLLocationDistance
  //var identifier: String
  var noteEntry: String
  var noteExit: String
  var fenceTitle: String
  var email: String
  var address: String
  
  var title: String? {
    return "Radius: \(radius)m "
  }
  var subtitle: String? {
    return "EntryAlert: \(noteEntry);ExitAlert: \(noteExit)"
  }
  init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance,  noteEntry: String,noteExit: String,fenceTitle: String,email: String,address: String){
    self.coordinate = coordinate
    self.radius = radius
    //  self.identifier = identifier
    self.noteEntry = noteEntry
    self.noteExit = noteExit
    self.fenceTitle = fenceTitle
    self.email = email
    self.address = address
    
  }
  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let latitude = try values.decode(Double.self, forKey: .latitude)
    let longitude = try values.decode(Double.self, forKey: .longitude)
    coordinate = CLLocationCoordinate2DMake(latitude, longitude)
    radius = try values.decode(Double.self, forKey: .radius)
    //  identifier = try values.decode(String.self, forKey: .identifier)
    noteEntry = try values.decode(String.self, forKey: .noteEntry)
    noteExit = try values.decode(String.self, forKey: .noteExit)
    fenceTitle = try values.decode(String.self, forKey: .fenceTitle)
    email = try values.decode(String.self, forKey: .email)
    address = try values.decode(String.self, forKey: .address)
  }
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(coordinate.latitude, forKey: .latitude)
    try container.encode(coordinate.longitude, forKey: .longitude)
    try container.encode(radius, forKey: .radius)
    try container.encode(noteEntry, forKey: .noteEntry)
    try container.encode(noteExit, forKey: .noteExit)
    try container.encode(fenceTitle, forKey: .fenceTitle)
    try container.encode(email, forKey: .email)
    try container.encode(address, forKey: .address)
  }
}
extension FenceWatch {
  public class func allFences() -> [FenceWatch] {
    guard let savedData = UserDefaults.standard.data(forKey: "savedItems") else { return [] }
    let decoder = JSONDecoder()
    if let savedFences = try? decoder.decode(Array.self, from: savedData) as [FenceWatch] {
      return savedFences
    }
    return []
  }
}
