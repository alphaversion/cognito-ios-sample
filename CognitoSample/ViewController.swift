//
//  ViewController.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/05/10.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider
import OAuthSwift
import AWSAPIGateway
import Apollo
import AuthenticationServices

class TwitterIdentityProvider: NSObject, AWSIdentityProviderManager {
    let credential: OAuthSwiftCredential
    init(_ credential: OAuthSwiftCredential) {
        self.credential = credential
    }
    func logins() -> AWSTask<NSDictionary> {
        let token = "\(credential.oauthToken);\(credential.oauthTokenSecret)"
        return AWSTask(result: ["api.twitter.com": token])
    }
}

class CognitoIdentityProvider: NSObject, AWSIdentityProviderManager {
    let userPool: AWSCognitoIdentityUserPool
    let token: String
    init(_ userPool: AWSCognitoIdentityUserPool, token: String) {
        self.userPool = userPool
        self.token = token
    }
    func logins() -> AWSTask<NSDictionary> {
        return AWSTask(result: [userPool.identityProviderName: token])
    }
}

class ViewController: UIViewController, OAuthSwiftURLHandlerType {
    var userPool: AWSCognitoIdentityUserPool?
    var oauthswift: OAuth1Swift?
    var oauthRequestHandle: OAuthSwiftRequestHandle?
    var authSession: ASWebAuthenticationSession?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "login",
            let vc = segue.destination as? LoginViewController,
            let sender = sender as? AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails> {
            vc.passwordAuthenticationCompletionSource = sender
            vc.userPool = userPool
        }
    }

    @IBAction func twitterSignin(_ sender: Any) {
        let oauthswift = OAuth1Swift(
            consumerKey:    twitterConsumerKey,
            consumerSecret: twitterConsumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        oauthswift.authorizeURLHandler = self
        oauthRequestHandle = oauthswift.authorize(
            withCallbackURL: URL(string: twitterOAuthCallbackURL)!,
            success: { credential, response, parameters in
                self.setupCognito(TwitterIdentityProvider(credential))
        },
            failure: { error in
                print(error.localizedDescription)
        })
        self.oauthswift = oauthswift
    }

    @IBAction func emailSignin(_ sender: Any) {
        let configuration = AWSServiceConfiguration(region: awsRegion, credentialsProvider: nil)

        let userPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration(
            clientId: cognitoClientId,
            clientSecret: cognitoClisentSecret,
            poolId: cognitoUserPoolId)

        AWSCognitoIdentityUserPool.register(
            with: configuration,
            userPoolConfiguration: userPoolConfiguration,
            forKey: cognitoUserPoolKey
        )

        AWSServiceManager.default().defaultServiceConfiguration = configuration

        let userPool = AWSCognitoIdentityUserPool(forKey: cognitoUserPoolKey)
        userPool.delegate = self
        userPool.currentUser()?.getSession().continueWith { t in
            if let error = t.error {
                print(error.localizedDescription)
                return nil
            }
            guard let userPool = self.userPool else {
                return nil
            }
            self.setupCognito(CognitoIdentityProvider(userPool, token: t.result!.idToken!.tokenString))
            return nil
        }
        self.userPool = userPool
    }

    @IBAction func signout(_ sender: Any) {
        userPool?.clearAll()
    }

    // MARK: -
    
    func handle(_ url: URL) {
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "cognito-sample://") { [weak self] (url, error) in
            self?.authSession = nil
            if let url = url {
                OAuthSwift.handle(url: url)
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        session.start()
        authSession = session
    }

    func requestSampleAPI(_ configuration: AWSServiceConfiguration) {
        let apollo = ApolloClient(networkTransport: APIGatewayNetworkTransport(
            url: URL(string: apiEndpoint)!,
            awsConfiguration: configuration))
        apollo.fetch(query: HelloQuery()) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print(result?.data?.hello)
            }
        }
    }

    func setupCognito(_ idpManager: AWSIdentityProviderManager? = nil) {
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: awsRegion,
            identityPoolId: cognitoIdentityPoolId,
            identityProviderManager: idpManager)

        let configuration = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: credentialsProvider)!
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        requestSampleAPI(configuration)
    }
    
}

extension ViewController: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        return self
    }
}

extension ViewController: AWSCognitoIdentityPasswordAuthentication {
    func didCompleteStepWithError(_ error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }

    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.performSegue(withIdentifier: "login", sender: passwordAuthenticationCompletionSource)
    }
}
