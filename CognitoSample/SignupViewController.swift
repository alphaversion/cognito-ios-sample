//
//  SignupViewController.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/06/10.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider
import OAuthSwift
import AWSAPIGateway

class SignupViewController: BaseViewController {
    @IBOutlet weak var inputUsername: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputEmail: UITextField!

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
            let password = inputPassword.text,
            let email = inputEmail.text
            else { return }
        if username == "" {
            showError(ErrorMessage("Username is empty"))
            return
        }
        if password == "" {
            showError(ErrorMessage("Password is empty"))
            return
        }
        if email == "" {
            showError(ErrorMessage("Email is empty"))
            return
        }
        Authenticator.default.signup(
            username: username,
            email: email,
            password: password) { session, error in
                if let error = error {
                    self.showError(error)
                } else {
                    self.requestSampleAPI()
                }
        }
    }
}
