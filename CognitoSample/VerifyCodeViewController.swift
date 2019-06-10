//
//  VerifyCodeViewController.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/06/10.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit

class VerifyCodeViewController: BaseViewController {
    @IBOutlet weak var inputCode: UITextField!


    @IBAction func verify(_ sender: Any) {
        guard
            let code = inputCode.text
            else { return }
        if code == "" {
            showError(ErrorMessage("Code is empty"))
            return
        }
        Authenticator.default.verify(code: code) { (session, error) in
            if let error = error {
                self.showError(error)
            } else {
                self.requestSampleAPI()
            }
        }
    }
}
