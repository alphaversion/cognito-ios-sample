//
//  Authenticator.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/05/15.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import Foundation
import AWSCore
import AWSCognitoIdentityProvider

class Authenticator {
    private static var _default: Authenticator?
    static var `default`: Authenticator {
        if let authenticator = _default {
            return authenticator
        }
        _default = Authenticator()
        AWSCognitoIdentityUserPool.register(
            with: serviceConfiguration,
            userPoolConfiguration: userPoolConfiguration,
            forKey: cognitoUserPoolKey
        )
        return _default!
    }
    
    static let serviceConfiguration = AWSServiceConfiguration(region: awsRegion, credentialsProvider: nil)
    
    static let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
        clientId: cognitoClientId,
        clientSecret: cognitoClisentSecret,
        poolId: cognitoUserPoolId)
    
    lazy var userPool: AWSCognitoIdentityUserPool = {
        return AWSCognitoIdentityUserPool(forKey: cognitoUserPoolKey)
    }()
    
    func signupWithTwitter() {
    }
    
    func signup(username: String, password: String) {
    }
    
    func signinWithTwitter() {
    }
    
    func signin(username: String, password: String) {
    }
    
    func signout() {
        userPool.clearLastKnownUser()
        userPool.clearAll()
    }

    class PasswordAuthentication: NSObject, AWSCognitoIdentityPasswordAuthentication {
        func didCompleteStepWithError(_ error: Error?) {
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        func getDetails(
            _ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput,
            passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        }
    }
    
    
    class TwitterAuthentication: NSObject, AWSCognitoIdentityCustomAuthentication {
        func didCompleteStepWithError(_ error: Error?) {
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        func getCustomChallengeDetails(
            _ authenticationInput: AWSCognitoIdentityCustomAuthenticationInput,
            customAuthCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityCustomChallengeDetails>) {
            
        }
    }
}
