//
//  LoginViewController.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/05/13.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit
import AWSCore
import AWSCognitoIdentityProvider

class LoginViewController: UIViewController {
    @IBOutlet weak var inputUsername: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    var userPool: AWSCognitoIdentityUserPool!
    var passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>!

    @IBAction func signin(_ sender: Any) {
        guard
            let username = inputUsername.text,
            let password = inputPassword.text
            else { return }
        let details = AWSCognitoIdentityPasswordAuthenticationDetails(username: username, password: password)
        passwordAuthenticationCompletionSource.set(result: details)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func signup(_ sender: Any) {
        guard
            let username = inputUsername.text,
            let password = inputPassword.text
            else { return }
        userPool.signUp(username, password: password, userAttributes: nil, validationData: nil).continueWith { t in
            if let error = t.error {
                print(error.localizedDescription)
                return nil
            }
            let details = AWSCognitoIdentityPasswordAuthenticationDetails(username: username, password: password)
            self.passwordAuthenticationCompletionSource.set(result: details)
            self.dismiss(animated: true, completion: nil)
            return nil
        }
    }
}
