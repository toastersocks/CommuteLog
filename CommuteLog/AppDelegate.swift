//
//  AppDelegate.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/18/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var manager: AppManager = AppManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        manager.startUp()
        return true
    }

}

