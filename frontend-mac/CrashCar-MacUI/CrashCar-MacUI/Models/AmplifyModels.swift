// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

nonisolated final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "b64de15bfa864ab40097bd2222a1140c"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Incident.self)
    ModelRegistry.register(modelType: TrafficAidPost.self)
  }
}