//
//  AppDelegate.swift
//  TouchLocker
//
//  Created by Ruben on 8/4/14.
//  Copyright (c) 2014 Ruben. All rights reserved.
//

import UIKit
import CoreData
import LocalAuthentication

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {
    var window    : UIWindow?
    var blockade  : UIView?
    var unlockBtn : UIButton?

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
            // app already launched, proceed as normal
            blur()
            authenticate()
        }
        else {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunched")
            NSUserDefaults.standardUserDefaults().synchronize()
            // This is the first launch ever
            var alert = UIAlertView(title: "First...",
                message: "Before you get started, please set a backup password in case your fingerprint is unavailable.",
                delegate: self,
                cancelButtonTitle: "Set Backup Passcode")
            alert.alertViewStyle = UIAlertViewStyle.SecureTextInput
            alert.tag = 0
            alert.show()
        }
        return true
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if let passwordField = alertView.textFieldAtIndex(0) {
            if alertView.tag == 0 {
                NSUserDefaults.standardUserDefaults().setValue(passwordField.text, forKey: "locker-pass")
                var alert = UIAlertView(title: "Get Started",
                    message: "Thank you! To get started, add photos to your locker by tapping the album icon on the top left, or add a new photo directly by tapping the camera icon on the top right.",
                    delegate: self,
                    cancelButtonTitle: "Continue")
                alert.show()
            } else if alertView.tag == 1 && NSUserDefaults.standardUserDefaults().valueForKey("locker-pass") as NSString == passwordField.text {
                UIView.animateWithDuration(
                    0.5,
                    animations: {
                        void in
                        self.blockade!.alpha = 0
                    },
                    completion:{
                        bool in
                        self.blockade!.removeFromSuperview()
                        //remove button to reinitiate auth
                        self.unlockBtn!.hidden = true
                        self.blockade!.alpha = 1
                })
            }
        }
    }
    
    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        blur()
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        authenticate()
    }

    func blur() {
        if let window = self.window {
            if self.blockade == nil {
                var effect    = UIBlurEffect(style: UIBlurEffectStyle.Light)
                self.blockade = UIVisualEffectView(effect: effect)
                self.blockade!.frame = window.frame
            }

            if !self.blockade!.isDescendantOfView(window) {
                window.makeKeyAndVisible()
                window.addSubview(blockade!)
                window.bringSubviewToFront(blockade!)

                var centeredRect = CGRect(x: window.frame.midX - 50, y: window.frame.midY - 25, width: 100, height: 50)
                self.unlockBtn = UIButton(frame: centeredRect)
                self.unlockBtn!.hidden = true
                self.unlockBtn!.backgroundColor      = UIColor(white: 0.8, alpha: 0.3)
                self.unlockBtn!.titleLabel!.textColor = UIColor.whiteColor()
                self.unlockBtn!.setTitle("Unlock", forState: UIControlState.Normal)
                self.unlockBtn!.addTarget(self, action: "authenticate", forControlEvents: UIControlEvents.TouchUpInside)

                self.blockade!.addSubview(self.unlockBtn!)
                self.blockade!.bringSubviewToFront(self.unlockBtn!)
            }
        }
    }

    func authenticate() {
        var context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Place your finger on the home button to unlock.", reply: { (success, error) in
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    if success { //authentication successful
                        UIView.animateWithDuration(
                            0.5,
                            animations: {
                                void in
                                self.blockade!.alpha = 0
                            },
                            completion:{
                                bool in
                                self.blockade!.removeFromSuperview()
                                //remove button to reinitiate auth
                                self.unlockBtn!.hidden = true
                                self.blockade!.alpha = 1
                            })
                    } else { //could not authenticate
                        var alertMessage = ""
                        switch error.code {
                            case LAError.UserFallback.toRaw():
                                alertMessage = "Enter your backup passcode to continue:"
                                var alert = UIAlertView(title: "Locked",
                                    message: alertMessage,
                                    delegate: self,
                                    cancelButtonTitle: "OK")
                                alert.tag = 1
                                alert.alertViewStyle = UIAlertViewStyle.SecureTextInput
                                alert.show()
                            case LAError.UserCancel.toRaw():
                                alertMessage = "Sorry, you must provide your fingerprint to unlock your photos."
                                var alert = UIAlertView(title: "Locked",
                                    message: alertMessage,
                                    delegate: self,
                                    cancelButtonTitle: "OK")
                                alert.show()
                            default:
                                alertMessage = "There was an error reading your fingerprint."
                                var alert = UIAlertView(title: "Locked",
                                    message: alertMessage,
                                    delegate: self,
                                    cancelButtonTitle: "OK")
                                alert.show()
                        }
                        
                        self.unlockBtn!.hidden = false
                    }
                })
            })
        } else {
            var alert = UIAlertView(title: "Biometrics Error",
                message: "It seems you have not set up a fingerprint yet. Please go to Settings > Touch ID and do so before using this application.",
                delegate: self,
                cancelButtonTitle: "OK")
            alert.show()
        }
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

}

