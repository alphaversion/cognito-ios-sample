//
//  ApolloClientExtension.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/05/16.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import Foundation
import Apollo
import AWSCore

extension ApolloClient {
    private static var _default: ApolloClient?
    static var `default`: ApolloClient {
        if let client = _default {
            return client
        }
        _default = ApolloClient(networkTransport: APIGatewayNetworkTransport(url: URL(string: apiEndpoint)!))
        return _default!
    }
}
