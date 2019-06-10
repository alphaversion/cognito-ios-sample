//
//  SigninViewController.swift
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
import Apollo

class SigninViewController: BaseViewController {
    @IBOutlet weak var inputUsername: UITextField!
    @IBOutlet weak var inputPassword: UITextField!

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
}
