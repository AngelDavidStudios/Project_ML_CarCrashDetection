// swiftlint:disable all
import Amplify
import Foundation

public nonisolated struct Incident: Model {
  public let id: String
  public var detectedAt: Temporal.DateTime
  public var location: String?
  public var latitude: Double?
  public var longitude: Double?
  public var confidenceScore: Double
  public var imageUrl: String?
  public var thumbnailUrl: String?
  public var s3ImageKey: String?
  public var verificationStatus: IncidentVerificationStatus?
  public var verifiedAt: Temporal.DateTime?
  public var verifiedByName: String?
  public var verifiedByEmail: String?
  public var incidentType: IncidentIncidentType?
  public var severity: IncidentSeverity?
  public var notes: String?
  public var responseNeeded: Bool
  public var responseInitiated: Bool
  public var resolvedAt: Temporal.DateTime?
  public var resolvedByName: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      detectedAt: Temporal.DateTime,
      location: String? = nil,
      latitude: Double? = nil,
      longitude: Double? = nil,
      confidenceScore: Double,
      imageUrl: String? = nil,
      thumbnailUrl: String? = nil,
      s3ImageKey: String? = nil,
      verificationStatus: IncidentVerificationStatus? = nil,
      verifiedAt: Temporal.DateTime? = nil,
      verifiedByName: String? = nil,
      verifiedByEmail: String? = nil,
      incidentType: IncidentIncidentType? = nil,
      severity: IncidentSeverity? = nil,
      notes: String? = nil,
      responseNeeded: Bool,
      responseInitiated: Bool,
      resolvedAt: Temporal.DateTime? = nil,
      resolvedByName: String? = nil) {
    self.init(id: id,
      detectedAt: detectedAt,
      location: location,
      latitude: latitude,
      longitude: longitude,
      confidenceScore: confidenceScore,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      s3ImageKey: s3ImageKey,
      verificationStatus: verificationStatus,
      verifiedAt: verifiedAt,
      verifiedByName: verifiedByName,
      verifiedByEmail: verifiedByEmail,
      incidentType: incidentType,
      severity: severity,
      notes: notes,
      responseNeeded: responseNeeded,
      responseInitiated: responseInitiated,
      resolvedAt: resolvedAt,
      resolvedByName: resolvedByName,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      detectedAt: Temporal.DateTime,
      location: String? = nil,
      latitude: Double? = nil,
      longitude: Double? = nil,
      confidenceScore: Double,
      imageUrl: String? = nil,
      thumbnailUrl: String? = nil,
      s3ImageKey: String? = nil,
      verificationStatus: IncidentVerificationStatus? = nil,
      verifiedAt: Temporal.DateTime? = nil,
      verifiedByName: String? = nil,
      verifiedByEmail: String? = nil,
      incidentType: IncidentIncidentType? = nil,
      severity: IncidentSeverity? = nil,
      notes: String? = nil,
      responseNeeded: Bool,
      responseInitiated: Bool,
      resolvedAt: Temporal.DateTime? = nil,
      resolvedByName: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.detectedAt = detectedAt
      self.location = location
      self.latitude = latitude
      self.longitude = longitude
      self.confidenceScore = confidenceScore
      self.imageUrl = imageUrl
      self.thumbnailUrl = thumbnailUrl
      self.s3ImageKey = s3ImageKey
      self.verificationStatus = verificationStatus
      self.verifiedAt = verifiedAt
      self.verifiedByName = verifiedByName
      self.verifiedByEmail = verifiedByEmail
      self.incidentType = incidentType
      self.severity = severity
      self.notes = notes
      self.responseNeeded = responseNeeded
      self.responseInitiated = responseInitiated
      self.resolvedAt = resolvedAt
      self.resolvedByName = resolvedByName
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}