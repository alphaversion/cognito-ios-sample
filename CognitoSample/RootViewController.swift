//
//  RootViewController.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/06/10.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit

class RootViewController: BaseViewController {

    @IBAction func signout(_ sender: Any) {
        Authenticator.default.signout()
    }
}
