//  This file was automatically generated and should not be edited.

import Apollo

public final class HelloQuery: GraphQLQuery {
  public let operationDefinition =
    "query Hello {\n  hello\n}"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("hello", type: .scalar(String.self)),
    ]

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(hello: String? = nil) {
      self.init(unsafeResultMap: ["__typename": "Query", "hello": hello])
    }

    public var hello: String? {
      get {
        return resultMap["hello"] as? String
      }
      set {
        resultMap.updateValue(newValue, forKey: "hello")
      }
    }
  }
}