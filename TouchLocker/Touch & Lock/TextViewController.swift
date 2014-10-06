//
//  TextViewController.swift
//  TouchLocker
//
//  Created by Ruben on 10/4/14.
//  Copyright (c) 2014 Ruben. All rights reserved.
//

import UIKit

class TextViewController : UIViewController, UITextViewDelegate {
    var textURL : String?
    var text : String?
    var keyboardIsShown : Bool?
    @IBOutlet var textView : UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.automaticallyAdjustsScrollViewInsets = false
        textView.text = text
        textView.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: self.view.window)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: self.view.window)
        
        self.keyboardIsShown = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: self.view.window)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: self.view.window)
    }
    
    func keyboardWillHide(notification : NSNotification) {
        var userInfo = notification.userInfo as [NSObject : AnyObject]!
        
        var keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue().size
        
        var contentInsets = UIEdgeInsetsZero
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
        
        var viewFrame = self.textView.frame
        
        viewFrame.size.height += keyboardSize!.height
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        self.textView.frame = viewFrame
        UIView.commitAnimations()
        
        self.keyboardIsShown = false
    }
    
    func keyboardWillShow(notification : NSNotification) {
        if self.keyboardIsShown! {
            return
        }
        
        var userInfo = notification.userInfo as [NSObject : AnyObject]!
        
        var keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue().size
        
        var contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize!.height, 0.0)
        textView.contentInset = contentInsets
        textView.scrollIndicatorInsets = contentInsets
        
        var viewFrame = self.textView.frame
        viewFrame.size.height -= keyboardSize!.height
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        self.textView.frame = viewFrame
        UIView.commitAnimations()
        
        self.keyboardIsShown = true
    }
    
    func setTextURL(url : String, text : String) {
        self.text = text
        self.textURL = url
    }
    
    func textViewDidChange(textView: UITextView) {
        (self.textView.text as NSString).writeToFile(self.textURL!, atomically: false, encoding: NSASCIIStringEncoding, error: nil)
    }
    
    @IBAction func shareExternal(sender: AnyObject) {
        var items = [AnyObject]()
        items.append(self.text!)
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
}