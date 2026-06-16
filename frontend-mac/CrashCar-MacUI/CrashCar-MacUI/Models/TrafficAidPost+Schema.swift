// swiftlint:disable all
import Amplify
import Foundation

nonisolated extension TrafficAidPost {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case address
    case latitude
    case longitude
    case contactNumber
    case hasPoliceService
    case hasAmbulance
    case hasFireService
    case operatingHours
    case additionalInfo
    case status
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let trafficAidPost = TrafficAidPost.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Operators"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "TrafficAidPosts"
    model.syncPluralName = "TrafficAidPosts"
    
    model.attributes(
      .primaryKey(fields: [trafficAidPost.id])
    )
    
    model.fields(
      .field(trafficAidPost.id, is: .required, ofType: .string),
      .field(trafficAidPost.name, is: .required, ofType: .string),
      .field(trafficAidPost.address, is: .required, ofType: .string),
      .field(trafficAidPost.latitude, is: .required, ofType: .double),
      .field(trafficAidPost.longitude, is: .required, ofType: .double),
      .field(trafficAidPost.contactNumber, is: .required, ofType: .string),
      .field(trafficAidPost.hasPoliceService, is: .required, ofType: .bool),
      .field(trafficAidPost.hasAmbulance, is: .required, ofType: .bool),
      .field(trafficAidPost.hasFireService, is: .required, ofType: .bool),
      .field(trafficAidPost.operatingHours, is: .required, ofType: .string),
      .field(trafficAidPost.additionalInfo, is: .optional, ofType: .string),
      .field(trafficAidPost.status, is: .required, ofType: .string),
      .field(trafficAidPost.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(trafficAidPost.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public nonisolated class Path: ModelPath<TrafficAidPost> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension TrafficAidPost: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
nonisolated extension ModelPath where ModelType == TrafficAidPost {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var name: FieldPath<String>   {
      string("name") 
    }
  public var address: FieldPath<String>   {
      string("address") 
    }
  public var latitude: FieldPath<Double>   {
      double("latitude") 
    }
  public var longitude: FieldPath<Double>   {
      double("longitude") 
    }
  public var contactNumber: FieldPath<String>   {
      string("contactNumber") 
    }
  public var hasPoliceService: FieldPath<Bool>   {
      bool("hasPoliceService") 
    }
  public var hasAmbulance: FieldPath<Bool>   {
      bool("hasAmbulance") 
    }
  public var hasFireService: FieldPath<Bool>   {
      bool("hasFireService") 
    }
  public var operatingHours: FieldPath<String>   {
      string("operatingHours") 
    }
  public var additionalInfo: FieldPath<String>   {
      string("additionalInfo") 
    }
  public var status: FieldPath<String>   {
      string("status") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}