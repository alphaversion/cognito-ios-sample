//
//  APIGatewayNetworkTransport.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/05/13.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import Foundation
import Apollo
import AWSCore

public class APIGatewayNetworkTransport: NetworkTransport {
    let url: URL
    let session: URLSession
    let serializationFormat = JSONSerializationFormat.self
    let awsConfiguration: AWSServiceConfiguration

    public init(url: URL, configuration: URLSessionConfiguration = URLSessionConfiguration.default, awsConfiguration: AWSServiceConfiguration, sendOperationIdentifiers: Bool = false) {
        self.url = url
        self.session = URLSession(configuration: configuration)
        self.sendOperationIdentifiers = sendOperationIdentifiers
        self.awsConfiguration = awsConfiguration
    }

    public func send<Operation>(operation: Operation, completionHandler: @escaping (_ response: GraphQLResponse<Operation>?, _ error: Error?) -> Void) -> Cancellable {
        let request = URLRequest(url: url) as! NSMutableURLRequest
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = requestBody(for: operation)
        request.httpBody = try! serializationFormat.serialize(value: body)
        request.addValue(NSDate().aws_stringValue(AWSDateISO8601DateFormat2), forHTTPHeaderField: "X-Amz-Date")

        let endpoint = AWSEndpoint(region: awsConfiguration.regionType, service: .APIGateway, url: url)
        let signer: AWSSignatureV4Signer = AWSSignatureV4Signer(credentialsProvider: awsConfiguration.credentialsProvider, endpoint: endpoint)
        signer.interceptRequest(request)

        let task = session.dataTask(with: request as URLRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                completionHandler(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                fatalError("Response should be an HTTPURLResponse")
            }

            if (!(200..<300).contains(httpResponse.statusCode)) {
                completionHandler(nil, GraphQLHTTPResponseError(body: data, response: httpResponse, kind: .errorResponse))
                return
            }

            guard let data = data else {
                completionHandler(nil, GraphQLHTTPResponseError(body: nil, response: httpResponse, kind: .invalidResponse))
                return
            }

            do {
                guard let body =  try self.serializationFormat.deserialize(data: data) as? JSONObject else {
                    throw GraphQLHTTPResponseError(body: data, response: httpResponse, kind: .invalidResponse)
                }
                let response = GraphQLResponse(operation: operation, body: body)
                completionHandler(response, nil)
            } catch {
                completionHandler(nil, error)
            }
        }

        task.resume()

        return task
    }

    private let sendOperationIdentifiers: Bool

    private func requestBody<Operation: GraphQLOperation>(for operation: Operation) -> GraphQLMap {
        if sendOperationIdentifiers {
            guard let operationIdentifier = operation.operationIdentifier else {
                preconditionFailure("To send operation identifiers, Apollo types must be generated with operationIdentifiers")
            }
            return ["id": operationIdentifier, "variables": operation.variables]
        }
        return ["query": operation.queryDocument, "variables": operation.variables]
    }
}
