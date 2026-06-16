// swiftlint:disable all
import Amplify
import Foundation

public nonisolated enum IncidentIncidentType: String, EnumPersistable {
  case vehicleCollision = "VEHICLE_COLLISION"
  case fire = "FIRE"
  case pedestrianAccident = "PEDESTRIAN_ACCIDENT"
  case debrisOnRoad = "DEBRIS_ON_ROAD"
  case stoppedVehicle = "STOPPED_VEHICLE"
  case wrongWayDriver = "WRONG_WAY_DRIVER"
  case other = "OTHER"
}