// swiftlint:disable all
import Amplify
import Foundation

public nonisolated enum IncidentVerificationStatus: String, EnumPersistable {
  case pending = "PENDING"
  case approved = "APPROVED"
  case rejected = "REJECTED"
}