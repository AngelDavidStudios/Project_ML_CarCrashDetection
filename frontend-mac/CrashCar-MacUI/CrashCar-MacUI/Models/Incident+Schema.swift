// swiftlint:disable all
import Amplify
import Foundation

nonisolated extension Incident {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case detectedAt
    case location
    case latitude
    case longitude
    case confidenceScore
    case imageUrl
    case thumbnailUrl
    case s3ImageKey
    case verificationStatus
    case verifiedAt
    case verifiedByName
    case verifiedByEmail
    case incidentType
    case severity
    case notes
    case responseNeeded
    case responseInitiated
    case resolvedAt
    case resolvedByName
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let incident = Incident.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Operators"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Incidents"
    model.syncPluralName = "Incidents"
    
    model.attributes(
      .primaryKey(fields: [incident.id])
    )
    
    model.fields(
      .field(incident.id, is: .required, ofType: .string),
      .field(incident.detectedAt, is: .required, ofType: .dateTime),
      .field(incident.location, is: .optional, ofType: .string),
      .field(incident.latitude, is: .optional, ofType: .double),
      .field(incident.longitude, is: .optional, ofType: .double),
      .field(incident.confidenceScore, is: .required, ofType: .double),
      .field(incident.imageUrl, is: .optional, ofType: .string),
      .field(incident.thumbnailUrl, is: .optional, ofType: .string),
      .field(incident.s3ImageKey, is: .optional, ofType: .string),
      .field(incident.verificationStatus, is: .optional, ofType: .enum(type: IncidentVerificationStatus.self)),
      .field(incident.verifiedAt, is: .optional, ofType: .dateTime),
      .field(incident.verifiedByName, is: .optional, ofType: .string),
      .field(incident.verifiedByEmail, is: .optional, ofType: .string),
      .field(incident.incidentType, is: .optional, ofType: .enum(type: IncidentIncidentType.self)),
      .field(incident.severity, is: .optional, ofType: .enum(type: IncidentSeverity.self)),
      .field(incident.notes, is: .optional, ofType: .string),
      .field(incident.responseNeeded, is: .required, ofType: .bool),
      .field(incident.responseInitiated, is: .required, ofType: .bool),
      .field(incident.resolvedAt, is: .optional, ofType: .dateTime),
      .field(incident.resolvedByName, is: .optional, ofType: .string),
      .field(incident.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(incident.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public nonisolated class Path: ModelPath<Incident> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Incident: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
nonisolated extension ModelPath where ModelType == Incident {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var detectedAt: FieldPath<Temporal.DateTime>   {
      datetime("detectedAt") 
    }
  public var location: FieldPath<String>   {
      string("location") 
    }
  public var latitude: FieldPath<Double>   {
      double("latitude") 
    }
  public var longitude: FieldPath<Double>   {
      double("longitude") 
    }
  public var confidenceScore: FieldPath<Double>   {
      double("confidenceScore") 
    }
  public var imageUrl: FieldPath<String>   {
      string("imageUrl") 
    }
  public var thumbnailUrl: FieldPath<String>   {
      string("thumbnailUrl") 
    }
  public var s3ImageKey: FieldPath<String>   {
      string("s3ImageKey") 
    }
  public var verifiedAt: FieldPath<Temporal.DateTime>   {
      datetime("verifiedAt") 
    }
  public var verifiedByName: FieldPath<String>   {
      string("verifiedByName") 
    }
  public var verifiedByEmail: FieldPath<String>   {
      string("verifiedByEmail") 
    }
  public var notes: FieldPath<String>   {
      string("notes") 
    }
  public var responseNeeded: FieldPath<Bool>   {
      bool("responseNeeded") 
    }
  public var responseInitiated: FieldPath<Bool>   {
      bool("responseInitiated") 
    }
  public var resolvedAt: FieldPath<Temporal.DateTime>   {
      datetime("resolvedAt") 
    }
  public var resolvedByName: FieldPath<String>   {
      string("resolvedByName") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}