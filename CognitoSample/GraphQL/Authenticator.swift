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

typealias UserSessionCompletionHandler = (_ session: AWSCognitoIdentityUserSession?, _ error: Error?) -> Void
typealias ErrorCompletionHandler = (_ error: Error?) -> Void

struct SigninCredentials {
    let username: String;
    let password: String;
}

class Authenticator {
    var user: AWSCognitoIdentityUser?
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
    
    private var twitterAuthentication: TwitterAuthentication?
    private var pendingSigninCredentials: SigninCredentials?

    func verify(code: String, completion: @escaping UserSessionCompletionHandler) {
        guard let user = self.user, let username = pendingSigninCredentials?.username, let password = pendingSigninCredentials?.password else { return }
        pendingSigninCredentials = nil
        user.confirmSignUp(code).continueWith { t in
            if let error = t.error {
                completion(nil, error)
                return nil
            }
            return self.signin(username: username, password: password, completion: completion)
        }
    }
    
    func signupWithTwitter(_ completion: @escaping UserSessionCompletionHandler) {
        signout()
        twitterAuthentication = TwitterAuthentication()
        twitterAuthentication!.errorHandler = { error in
            completion(nil, error)
        }
        twitterAuthentication!.authorize(
            success: { credential, response, parameters in
                let token = "\(credential.oauthToken);\(credential.oauthTokenSecret)"
                let username = "api.twitter.com:\(String(describing: parameters["user_id"]!))"
                self.userPool.signUp(username, password: token, userAttributes: nil, validationData: nil).continueWith { t in
                    if let error = t.error {
                        completion(nil, error)
                        return nil
                    }
                    t.result!.user.getSession(username, password: token, validationData: nil).continueWith { t in
                        completion(t.result, t.error)
                    }
                    return nil
                }
        },
            failure: { error in
                completion(nil, error)
        })
    }
    
    func signup(username: String, email: String,  password: String, completion: @escaping UserSessionCompletionHandler) {
        signout()
        pendingSigninCredentials = SigninCredentials(username: username, password: password)
        userPool.signUp(username, password: password, userAttributes: [
            AWSCognitoIdentityUserAttributeType(name: "email", value: email)], validationData: nil).continueWith { t in
                if let error = t.error {
                    completion(nil, error)
                    return nil
                }
                let user = t.result!.user
                self.user = user
                user.getSession(username, password: password, validationData: nil).continueWith { t in
                    completion(t.result, t.error)
                }
                return nil
        }
    }
    
    func signinWithTwitter(_ completion: @escaping UserSessionCompletionHandler) {
        signout()
        twitterAuthentication = TwitterAuthentication()
        twitterAuthentication!.errorHandler = { error in
            completion(nil, error)
        }
        userPool.delegate = twitterAuthentication!
        userPool.getUser().getSession().continueWith { t in
            completion(t.result, t.error)
        }
    }
    
    func signin(username: String, password: String, completion: @escaping UserSessionCompletionHandler) {
        signout()
        pendingSigninCredentials = SigninCredentials(username: username, password: password)
        let user = userPool.getUser(username)
        self.user = user
        user.getSession(username, password: password, validationData: nil).continueWith { t in
            completion(t.result, t.error)
        }
    }
    
    func signout() {
        pendingSigninCredentials = nil
        twitterAuthentication?.cancel()
        userPool.currentUser()?.clearSession()
        userPool.clearLastKnownUser()
        userPool.clearAll()
    }
    
    class TwitterAuthentication: NSObject, AWSCognitoIdentityCustomAuthentication, AWSCognitoIdentityInteractiveAuthenticationDelegate {
        private var oauthRequestHandle: OAuthSwiftRequestHandle?
        var details: AWSCognitoIdentityCustomChallengeDetails?
        let oauth: OAuth1Swift
        var errorHandler: ErrorCompletionHandler?
        
        override init() {
            oauth = OAuth1Swift(
                consumerKey:    twitterConsumerKey,
                consumerSecret: twitterConsumerSecret,
                requestTokenUrl: "https://api.twitter.com/oauth/request_token",
                authorizeUrl:    "https://api.twitter.com/oauth/authorize",
                accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
            )
        }
        
        func authorize(success: @escaping OAuthSwift.TokenSuccessHandler, failure: OAuthSwift.FailureHandler?) {
            oauth.authorize(withCallbackURL: URL(string: twitterOAuthCallbackURL)!, success: success, failure: failure)
        }
        
        func cancel() {
            oauthRequestHandle?.cancel()
            oauthRequestHandle = nil
        }
        
        func startCustomAuthentication() -> AWSCognitoIdentityCustomAuthentication {
            return self
        }
        
        func didCompleteStepWithError(_ error: Error?) {
            if let _ = error {
                cancel()
                errorHandler?(error)
            }
        }
        
        func getCustomChallengeDetails(
            _ authenticationInput: AWSCognitoIdentityCustomAuthenticationInput,
            customAuthCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityCustomChallengeDetails>) {
            if let details = details {
                if authenticationInput.challengeParameters["USERNAME"] == details.challengeResponses["USERNAME"] {
                    customAuthCompletionSource.set(result: details)
                }
                return
            }
            authorize(success: { credential, response, parameters in
                let token = "\(credential.oauthToken);\(credential.oauthTokenSecret)"
                let username = "api.twitter.com:\(String(describing: parameters["user_id"]!))"
                let details = AWSCognitoIdentityCustomChallengeDetails(challengeResponses: [
                    "USERNAME": username, "ANSWER": token])
                self.details = details
                customAuthCompletionSource.set(result: details)
            }) { error in
                customAuthCompletionSource.set(error: error)
            }
        }
    }
}
