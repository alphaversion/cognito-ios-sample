//
//  BaseViewController.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/06/10.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit
import AWSCognitoIdentityProvider
import Apollo

struct ErrorMessage: LocalizedError {
    let message: String
    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}

class BaseViewController: UIViewController {

    func navigateToVerifyCode() {
        performSegue(withIdentifier: "verifyCode", sender: nil)
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
        case .some(.userNotConfirmed):
            DispatchQueue.main.async {
                self.navigateToVerifyCode()
            }
            return
        default:
            break
        }
        DispatchQueue.main.async {
            let av = UIAlertController(title: "Error", message: alertMsg, preferredStyle: .alert)
            av.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(av, animated: true)
        }
    }

    // MARK: -

    func requestSampleAPI() {
        ApolloClient.default.fetch(query: HelloQuery()) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print(result?.data?.hello ?? "(empty)")
            }
        }
    }
}
