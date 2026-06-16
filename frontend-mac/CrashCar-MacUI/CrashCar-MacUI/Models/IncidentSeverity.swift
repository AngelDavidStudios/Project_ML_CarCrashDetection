// swiftlint:disable all
import Amplify
import Foundation

public nonisolated enum IncidentSeverity: String, EnumPersistable {
  case critical = "CRITICAL"
  case major = "MAJOR"
  case minor = "MINOR"
}