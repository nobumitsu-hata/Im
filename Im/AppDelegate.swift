//
//  AppDelegate.swift
//  Im
//
//  Created by nobumitsu on 2019/03/11.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import FBSDKCoreKit
import GoogleSignIn
import TwitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    override init() {
        super.init()
        FirebaseApp.configure()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions) {
            return true
        }
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        TWTRTwitter.sharedInstance().start(withConsumerKey: "3EXKUF38fsBeZRh9LXCx3T9Fz", consumerSecret: "SeDtkaudc4chpRTjIMvZZU6T0xQ4vb7DLTYJwnBAOpjhEPyVPB")
        return true
    }
    
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:])
        -> Bool {
            
            if TWTRTwitter.sharedInstance().application(application, open: url, options: options) {
                return true
            }
            
            if ApplicationDelegate.shared.application(application,
                                                      open: url,
                                                      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                      annotation: [:]) {
                return true
            }
            
            if GIDSignIn.sharedInstance().handle(url,sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: [:]) {
                return true
            }
            
            return true
   
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        AppEvents.activateApp()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

//    func applicationDidBecomeActive(_ application: UIApplication) {
//        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

