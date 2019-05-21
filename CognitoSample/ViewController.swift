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

struct ErrorMessage: LocalizedError {
    let message: String
    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}

class ViewController: UIViewController, OAuthSwiftURLHandlerType {
    var userPool: AWSCognitoIdentityUserPool?
    var oauthswift: OAuth1Swift?
    var oauthRequestHandle: OAuthSwiftRequestHandle?
    var authSession: ASWebAuthenticationSession?

    @IBOutlet weak var inputUsername: UITextField!
    @IBOutlet weak var inputPassword: UITextField!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateInfo()
    }
    
    @IBAction func twitterSignin(_ sender: Any) {
        Authenticator.default.signinWithTwitter { session, error in
            if let error = error {
                self.showError(error)
            } else {
                self.requestSampleAPI()
            }
        }
    }

    @IBAction func emailSignin(_ sender: Any) {
        guard
            let username = inputUsername.text,
            let password = inputPassword.text
            else { return }
        if username == "" {
            showError(ErrorMessage("Username is empty"))
            return
        }
        if password == "" {
            showError(ErrorMessage("Password is empty"))
            return
        }
        Authenticator.default.signin(username: username, password: password) { session, error in
            if let error = error {
                self.showError(error)
            } else {
                self.requestSampleAPI()
            }
        }
    }

    @IBAction func twitterSignup(_ sender: Any) {
        Authenticator.default.signupWithTwitter { session, error in
            if let error = error {
                self.showError(error)
            } else {
                self.requestSampleAPI()
            }
        }
    }

    @IBAction func emailSignup(_ sender: Any) {
        guard
            let username = inputUsername.text,
            let password = inputPassword.text
            else { return }
        if username == "" {
            showError(ErrorMessage("Username is empty"))
            return
        }
        if password == "" {
            showError(ErrorMessage("Password is empty"))
            return
        }
        Authenticator.default.signup(username: username, password: password) { session, error in
            if let error = error {
                self.showError(error)
            } else {
                self.requestSampleAPI()
            }
        }
    }

    @IBAction func signout(_ sender: Any) {
        Authenticator.default.signout()
        updateInfo()
    }
    
    func updateInfo() {
        print("isSignIn: \(Authenticator.default.isSignIn)")
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

    func requestSampleAPI() {
        ApolloClient.default.fetch(query: HelloQuery()) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print(result?.data?.hello ?? "(empty)")
            }
        }
        
        updateInfo()
    }

    func showError(_ error: Error) {
        var alertMsg = (error as NSError).userInfo["message"] as? String ?? error.localizedDescription
        let errorType = AWSCognitoIdentityProviderErrorType(rawValue: (error as NSError).code)
        // https://git.io/fjl1C
        switch errorType {
        case .some(.userNotFound):
            alertMsg = "User not found"
            break
        case .some(.invalidPassword):
            alertMsg = "Invalid password"
            break
        default:
            break
        }
        DispatchQueue.main.async {
            let av = UIAlertController(title: "Error", message: alertMsg, preferredStyle: .alert)
            av.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(av, animated: true)
        }
    }
}
