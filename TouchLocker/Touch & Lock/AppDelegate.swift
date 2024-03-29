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
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // Don't backup documents directory!
        var docsDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! String
        var url      = NSURL(fileURLWithPath: docsDir)!
        url.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey, error: nil)
        
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
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
            // app already launched, blur
            blur()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if NSUserDefaults.standardUserDefaults().boolForKey("HasLaunched") {
            // app already launched, authenticate
            authenticate()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
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
        self.unlockBtn!.hidden = true //hide unlock button, since we're unlocking
        
        // attempt to authenticate via fingerprint
        var context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Place your finger on the home button to unlock.", reply: { (success, error) in
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    if success { //authentication successful
                        self.unlock()
                    } else { //could not authenticate
                        switch error.code {
                        case LAError.UserFallback.rawValue: //user chose to authenticate with passcode
                            self.authenticateWithPasscode()
                        case LAError.UserCancel.rawValue:   //user chose to cancel authentication
                            var alertMessage = "Sorry, you must provide your fingerprint or passcode to enter TouchLocker."
                            var cancelled = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                            var cancel = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                            cancelled.addAction(cancel)
                            UIApplication.sharedApplication().keyWindow!.rootViewController?.presentViewController(cancelled, animated: true, completion: nil)
                            self.unlockBtn!.hidden = false
                        default: //other authentication error
                            var alertMessage = "There was an error reading your fingerprint."
                            var error = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                            var okay = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                            error.addAction(okay)
                            UIApplication.sharedApplication().keyWindow!.rootViewController?.presentViewController(error, animated: true, completion: nil)
                            self.unlockBtn!.hidden = false
                        }
                    }
                })
            })
        } else { //if fingerprint unavailable, attempt unlock via passcode
            self.authenticateWithPasscode()
        }
    }
    
    //on first run, ask to setup passcode
    func promptToSetupPasscode(firstAttempt : Bool) {
        var title : String
        var message : String
        if firstAttempt { //ask to setup password
            title = "First..."
            message = "Before you get started, please set a passcode in case your fingerprint is unavailable."
            
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
                var passcodeField = promptToSetupPasscode.textFields?.first as! UITextField
                self.setupPasscode(passcodeField.text)
        })
        
        promptToSetupPasscode.addAction(setPasscode)
        
        window?.makeKeyAndVisible()
        window?.rootViewController?.presentViewController(promptToSetupPasscode, animated: true, completion: nil)
    }
    
    //set passcode if valid
    func setupPasscode(passcode : String) {
        if count(passcode) >= 4 { //good password length!
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunched")
            NSUserDefaults.standardUserDefaults().setValue(passcode, forKey: "locker-pass")
            NSUserDefaults.standardUserDefaults().synchronize()
            var getStarted = UIAlertController(title: "Thank you!",
                message: "To get started, tap the \"+\" icon to add to your TouchLocker. Locking photos will remove them from your Photo Library and lock them here.",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            var start = UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default, handler: nil)
            getStarted.addAction(start)
            
            window?.makeKeyAndVisible()
            window?.rootViewController?.presentViewController(getStarted, animated: true, completion: nil)
        } else { //not a good password length, prompt them again
            self.promptToSetupPasscode(false)
        }
    }
    
    //authenticate user with a passcode
    func authenticateWithPasscode() {
        var alertMessage = "Enter your passcode to unlock:"
        var passcodeAttempt = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
        passcodeAttempt.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.secureTextEntry = true
        })
        
        var attempt = UIAlertAction(title: "Unlock", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            var passcodeField = passcodeAttempt.textFields?.first as! UITextField
            
            //if password is correct
            if(NSUserDefaults.standardUserDefaults().valueForKey("locker-pass") as! String == passcodeField.text) {
                self.unlock()
            } else { //password incorrect, prompt to try again
                var alertMessage = "Sorry, that passcode is incorrect. Please try again."
                var tryAgain = UIAlertController(title: "Locked", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                var authenticate = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default) { (action) -> Void in
                    self.authenticate()
                }
                var cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
                    self.unlockBtn!.hidden = false
                }
                
                tryAgain.addAction(cancel)
                tryAgain.addAction(authenticate)
                UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(tryAgain, animated: true, completion: nil)
            }
        })
        var cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            self.unlockBtn!.hidden = false
        }
        passcodeAttempt.addAction(attempt)
        passcodeAttempt.addAction(cancel)
        UIApplication.sharedApplication().keyWindow!.rootViewController?.presentViewController(passcodeAttempt, animated: true, completion: nil)
    }

}

