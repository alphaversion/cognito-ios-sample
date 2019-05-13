//
//  AppDelegate.swift
//  CognitoSample
//
//  Created by Atsushi Nagase on 2019/05/10.
//  Copyright © 2019 instance0, inc. All rights reserved.
//

import UIKit
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        OAuthSwift.handle(url: url)
        return true
    }

}

