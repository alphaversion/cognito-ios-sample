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
import OAuthSwift

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
    
    lazy var twitterAuth: OAuth1Swift = {
        return OAuth1Swift(
            consumerKey:    twitterConsumerKey,
            consumerSecret: twitterConsumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
    }()
    
    private var twitterAuthentication: TwitterAuthentication?
    private var passwordAuthentication: PasswordAuthentication?
    private var oauthRequestHandle: OAuthSwiftRequestHandle?
    
    func signupWithTwitter() -> AWSTask<AWSCognitoIdentityUser> {
        signout()
        let task = AWSTask<AWSCognitoIdentityUser>(result: nil)
        return task.continueWith { t in
            t.continueWith { t in
                self.oauthRequestHandle = self.twitterAuth.authorize(
                    withCallbackURL: URL(string: twitterOAuthCallbackURL)!,
                    success: { credential, response, parameters in
                        let token = "\(credential.oauthToken);\(credential.oauthTokenSecret)"
                        let username = "api.twitter.com:\(String(describing: parameters["user_id"]))"
                        t.continueWith {_ in
                            return self.signup(username: username, password: token)
                        }
                },
                    failure: { error in
                        t.continueWith { _ in AWSTask<AWSCognitoIdentityUser>(error: error) }
                })
            }
            return nil
            } as! AWSTask<AWSCognitoIdentityUser>
    }
    
    func signup(username: String, password: String) -> AWSTask<AWSCognitoIdentityUserPoolSignUpResponse> {
        signout()
        return userPool.signUp(username, password: password, userAttributes: nil, validationData: nil)
    }
    
    func signinWithTwitter() -> AWSCognitoIdentityUser {
        signout()
        twitterAuthentication = TwitterAuthentication(oauth: self.twitterAuth)
        userPool.delegate = twitterAuthentication!
        return userPool.currentUser()!
    }
    
    func signin(username: String, password: String) -> AWSCognitoIdentityUser {
        signout()
        passwordAuthentication = PasswordAuthentication(username: username, password: password)
        userPool.delegate = passwordAuthentication!
        return userPool.currentUser()!
    }
    
    func signout() {
        oauthRequestHandle?.cancel()
        oauthRequestHandle = nil
        userPool.currentUser()?.clearSession()
        userPool.clearLastKnownUser()
        userPool.clearAll()
    }
    
    class TwitterAuthentication: NSObject, AWSCognitoIdentityCustomAuthentication, AWSCognitoIdentityInteractiveAuthenticationDelegate {
        let oauth: OAuth1Swift
        
        init(oauth: OAuth1Swift) {
            self.oauth = oauth
        }
        
        func startCustomAuthentication() -> AWSCognitoIdentityCustomAuthentication {
            return self
        }
        
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
    
    class PasswordAuthentication: NSObject, AWSCognitoIdentityPasswordAuthentication, AWSCognitoIdentityInteractiveAuthenticationDelegate {
        let username: String
        let password: String
        
        init(username: String, password: String) {
            self.username = username
            self.password = password
        }
        
        func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
            return self
        }
        
        func didCompleteStepWithError(_ error: Error?) {
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
            let details = AWSCognitoIdentityPasswordAuthenticationDetails(username: username, password: password)
            passwordAuthenticationCompletionSource.set(result: details)
        }
    }
}
