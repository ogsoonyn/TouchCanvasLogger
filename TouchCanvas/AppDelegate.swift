/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The application delegate.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func applicationWillResignActive(application: UIApplication) {
        // send home-key event to ViewController
        NSNotificationCenter.defaultCenter().postNotificationName("HomeKeyPressed", object: self)
        
    }
}
