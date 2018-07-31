//
//  ApplicationDelegate.swift
//  Test
//
//  Created by BB9z on 2018/7/31.
//  Copyright © 2018 RFUI. All rights reserved.
//

import UIKit

@UIApplicationMain
class ApplicationDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FLEXManager.shared().showExplorer()
        return true
    }
}
