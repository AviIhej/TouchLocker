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
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window    : UIWindow?
    var blockade  : UIView?
    var unlockBtn : UIButton?

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        // Override point for customization after application launch.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
            // app already launched, authenticate
            blur()
            authenticate()
        } else {
            // This is the first launch ever
            promptToSetupPasscode(true)
        }
        return true
    }
    
    func applicationWillResignActive(application: UIApplication!) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(application: UIApplication!) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
            // app already launched, blur
            blur()
        }
    }

    func applicationWillEnterForeground(application: UIApplication!) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
            // app already launched, authenticate
            authenticate()
        }
    }

    func applicationDidBecomeActive(application: UIApplication!) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication!) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
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
                window.rootViewController?.view.addSubview(blockade!)
                window.rootViewController?.view.bringSubviewToFront(blockade!)
                
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
    
    func unlock() {
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
    
    func authenticate() {
        var context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Place your finger on the home button to unlock.", reply: { (success, error) in
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    if success { //authentication successful
                        self.unlock()
                    } else { //could not authenticate
                        switch error.code {
                        case LAError.UserFallback.toRaw():
                            var alertMessage = "Enter your backup passcode to continue:"
                            var passcodeAttempt = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                            passcodeAttempt.addTextFieldWithConfigurationHandler({ (textField) -> Void in
                                textField.secureTextEntry = true
                            })
                            
                            var attempt = UIAlertAction(title: "Unlock", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                                var passcodeField = passcodeAttempt.textFields?.first as UITextField
                                if(NSUserDefaults.standardUserDefaults().valueForKey("locker-pass") as String == passcodeField.text) {
                                    self.unlock()
                                }
                            })
                            var cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
                            passcodeAttempt.addAction(attempt)
                            passcodeAttempt.addAction(cancel)
                            UIApplication.sharedApplication().keyWindow.rootViewController?.presentViewController(passcodeAttempt, animated: true, completion: nil)
                        case LAError.UserCancel.toRaw():
                            var alertMessage = "Sorry, you must provide your fingerprint to enter TouchLocker."
                            var cancelled = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                            var cancel = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                            cancelled.addAction(cancel)
                            UIApplication.sharedApplication().keyWindow.rootViewController?.presentViewController(cancelled, animated: true, completion: nil)
                        default:
                            var alertMessage = "There was an error reading your fingerprint."
                            var error = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                            var okay = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                            error.addAction(okay)
                            UIApplication.sharedApplication().keyWindow.rootViewController?.presentViewController(error, animated: true, completion: nil)
                        }
                        
                        self.unlockBtn!.hidden = false
                    }
                })
            })
        } else {
            var alertMessage = "It seems you have not set up a fingerprint yet. Please go to Settings > Touch ID and do so before using this application."
            var error = UIAlertController(title: "Biometrics Error", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
            var okay = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            error.addAction(okay)
            UIApplication.sharedApplication().keyWindow.rootViewController?.presentViewController(error, animated: true, completion: nil)
        }
    }
    
    func promptToSetupPasscode(firstAttempt : Bool) {
        var title : String
        var message : String
        if firstAttempt { //ask to setup password
            title = "First..."
            message = "Before you get started, please set a backup passcode in case your fingerprint is unavailable."
            
        } else { //password error (too short)
            title = "Oops..."
            message = "Sorry, that passcode is too short! Please make your passcode at least 4 characters."
        }
        
        var promptToSetupPasscode = UIAlertController(title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        
        promptToSetupPasscode.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.secureTextEntry = true
        })
        
        var setPasscode = UIAlertAction(title: "Set Backup Passcode",
            style: UIAlertActionStyle.Default,
            handler: {
                (action : UIAlertAction!) in
                var passcodeField = promptToSetupPasscode.textFields?.first as UITextField
                self.setupPasscode(passcodeField.text)
        })
        
        promptToSetupPasscode.addAction(setPasscode)
        
        window?.makeKeyAndVisible()
        window?.rootViewController?.presentViewController(promptToSetupPasscode, animated: true, completion: nil)
    }
    
    func setupPasscode(passcode : String) {
        if countElements(passcode) >= 4 { //good password length!
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunched")
            NSUserDefaults.standardUserDefaults().setValue(passcode, forKey: "locker-pass")
            NSUserDefaults.standardUserDefaults().synchronize()
            var getStarted = UIAlertController(title: "Get Started",
                message: "Thank you! To get started, add photos to your locker by tapping the album icon on the top left, or add a new photo directly by tapping the camera icon on the top right.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            var start = UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default, handler: nil)
            getStarted.addAction(start)
            
            window?.makeKeyAndVisible()
            window?.rootViewController?.presentViewController(getStarted, animated: true, completion: nil)
        } else {
            self.promptToSetupPasscode(false)
        }
    }

}

