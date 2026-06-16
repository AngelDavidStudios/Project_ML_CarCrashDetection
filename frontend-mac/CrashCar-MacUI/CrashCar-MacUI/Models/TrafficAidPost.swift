// swiftlint:disable all
import Amplify
import Foundation

public nonisolated struct TrafficAidPost: Model {
  public let id: String
  public var name: String
  public var address: String
  public var latitude: Double
  public var longitude: Double
  public var contactNumber: String
  public var hasPoliceService: Bool
  public var hasAmbulance: Bool
  public var hasFireService: Bool
  public var operatingHours: String
  public var additionalInfo: String?
  public var status: String
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      address: String,
      latitude: Double,
      longitude: Double,
      contactNumber: String,
      hasPoliceService: Bool,
      hasAmbulance: Bool,
      hasFireService: Bool,
      operatingHours: String,
      additionalInfo: String? = nil,
      status: String) {
    self.init(id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      contactNumber: contactNumber,
      hasPoliceService: hasPoliceService,
      hasAmbulance: hasAmbulance,
      hasFireService: hasFireService,
      operatingHours: operatingHours,
      additionalInfo: additionalInfo,
      status: status,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      address: String,
      latitude: Double,
      longitude: Double,
      contactNumber: String,
      hasPoliceService: Bool,
      hasAmbulance: Bool,
      hasFireService: Bool,
      operatingHours: String,
      additionalInfo: String? = nil,
      status: String,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.address = address
      self.latitude = latitude
      self.longitude = longitude
      self.contactNumber = contactNumber
      self.hasPoliceService = hasPoliceService
      self.hasAmbulance = hasAmbulance
      self.hasFireService = hasFireService
      self.operatingHours = operatingHours
      self.additionalInfo = additionalInfo
      self.status = status
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}