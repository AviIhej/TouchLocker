//
//  ViewController.swift
//  TouchLocker
//
//  Created by Ruben on 8/4/14.
//  Copyright (c) 2014 Ruben. All rights reserved.
//

import UIKit
import AssetsLibrary
import QuartzCore
import Photos

class ViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var previewTable : UITableView!
    var paths = [] as [String]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //menu for adding item to TouchLocker
    @IBAction func addToTouchLocker(sender : UIBarButtonItem) {
        let adding = UIAlertController(title: "Add to TouchLocker", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        let addText = UIAlertAction(title: "Text Snippet", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.addText()
        }
        let addPhotoFromCamera = UIAlertAction(title: "Photo from Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.addPhotoFromCamera()
        }
        let addPhotoFromAlbum = UIAlertAction(title: "Photo from Album", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.addPhotoFromAlbum()
        }
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        adding.addAction(addText)
        adding.addAction(addPhotoFromCamera)
        adding.addAction(addPhotoFromAlbum)
        adding.addAction(cancel)
        self.presentViewController(adding, animated: true, completion: nil)
    }
    
    //add text snippet to TouchLocker
    func addText() {
        //text snippet
        let addingText = UIAlertController(title: "Text Snippet", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        addingText.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.spellCheckingType = UITextSpellCheckingType.Yes
            textField.autocapitalizationType = UITextAutocapitalizationType.Sentences
            textField.autocorrectionType = UITextAutocorrectionType.Yes
        }
        
        let saveText = UIAlertAction(title: "Save", style: UIAlertActionStyle.Default) { (action) -> Void in
            var note = addingText.textFields?.first! as! UITextField
            self.lockText(note.text)
        }
        let cancel   = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)

        addingText.addAction(saveText)
        addingText.addAction(cancel)
        
        self.presentViewController(addingText, animated: true, completion: nil)
    }
    
    //take photo and add to TouchLocker
    func addPhotoFromCamera() {
        //photo from camera
        var imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
        imagePickerController.delegate   = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    //add existing photo to TouchLocker
    func addPhotoFromAlbum() {
        //photo from album
        var imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePickerController.delegate   = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    //save text and reload
    func lockText(text : String) {
        let rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! NSString
        let txtPath  = rootDir.stringByAppendingString("/text\(NSDate.timeIntervalSinceReferenceDate()).txt")
        
        text.writeToFile(txtPath,
                        atomically: false,
                          encoding: NSASCIIStringEncoding,
                             error: nil)
        
        self.addedNew("text", atPath: txtPath)
    }
    
    //save camera image and reload
    func lockImage(image : UIImage) {
        let rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! NSString
        let imgPath  = rootDir.stringByAppendingString("/photo\(NSDate.timeIntervalSinceReferenceDate()).jpg")
        
        let data     = UIImageJPEGRepresentation(image, 1)
        NSFileManager.defaultManager().createFileAtPath(imgPath, contents: data, attributes: nil)
        
        self.addedNew("image", atPath: imgPath)
    }
    
    //save album image and reload
    func lockImageAtURL(imagePath : NSURL) {
        var assetLibrary = ALAssetsLibrary()
        assetLibrary.assetForURL(imagePath, resultBlock: { (asset) in
            let rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! NSString
            let imgPath  = rootDir.stringByAppendingString("/photo\(NSDate.timeIntervalSinceReferenceDate()).jpg")
            
            let rep    = asset.defaultRepresentation()
            let buff   = UnsafeMutablePointer<UInt8>.alloc(Int(rep.size()))
            let buffed = rep.getBytes(buff, fromOffset: 0, length: Int(rep.size()), error: nil)
            
            let data   = NSData(bytesNoCopy: buff, length: buffed, freeWhenDone: true)
            NSFileManager.defaultManager().createFileAtPath(imgPath, contents: data, attributes: nil)
            
            //delete old image & complete
            let asset = PHAsset.fetchAssetsWithALAssetURLs([imagePath], options: nil)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                PHAssetChangeRequest.deleteAssets(asset)
            }, completionHandler: { (success, error) -> Void in
                if success || error.code == -1 {
                    self.addedNew("existing image", atPath: imgPath)
                } else {
                    NSLog("error: \(error.code)")
                }
            })
            
            
        }, failureBlock: { (error) in
            NSLog("error: \(error.localizedDescription)")
        })
    }
    
    func addedNew(type: String, atPath path: String) {
        dispatch_async(dispatch_get_main_queue()) {
            //explicitly exclude item from iCloud backup
            NSURL(fileURLWithPath: path)!.setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey, error: nil)
            //reload table
            self.previewTable.reloadData()
            
            //help text
            if !NSUserDefaults.standardUserDefaults().boolForKey("HasntDeleted") {
                self.reminderHowToDeleteFromTouchLocker()
            }
        }
    }
    
    func reminderHowToDeleteFromTouchLocker() {
        let alert = UIAlertController(title: "Instructions",
            message: "To remove something from your locker, swipe the item to the left and press delete.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        let accept = UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasntDeleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        alert.addAction(accept)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //camera or album image picker
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        if picker.sourceType == UIImagePickerControllerSourceType.Camera {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            lockImage(image)
        }
        else if picker.sourceType == UIImagePickerControllerSourceType.PhotoLibrary {
            let imagePath = info[UIImagePickerControllerReferenceURL] as! NSURL
            lockImageAtURL(imagePath)
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.paths.removeAll(keepCapacity: false)
        
        let rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir  = rootDir[0] as! String
        let fileList = NSFileManager.defaultManager().contentsOfDirectoryAtPath(docsDir, error: nil) as! [String]
        
        //filter by files
        for filename in fileList {
            paths += ["\(docsDir)/\(filename)"]
        }

        return self.paths.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let path = self.paths[indexPath.row]
        
        if let img = UIImage(contentsOfFile: path) { //image settings
            let imageTableIdentifier = "ImageTableCell"
            
            var cell = tableView.dequeueReusableCellWithIdentifier(imageTableIdentifier as String) as? UITableViewCell
            
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: imageTableIdentifier)
            }
            
            cell!.tag = indexPath.row
        
            var imageView = UIImageView(image: img)
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.masksToBounds = true
            cell!.backgroundView = imageView
            cell!.layoutMargins = UIEdgeInsetsZero
            
            return cell!
        }
        if let txt = NSString(contentsOfFile: path, encoding: NSASCIIStringEncoding, error: nil) { //text settings
            let textTableIdentifier = "TextTableCell"
            
            var cell = tableView.dequeueReusableCellWithIdentifier(textTableIdentifier as String) as? UITableViewCell
            
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: textTableIdentifier)
            }
            
            cell!.tag = indexPath.row
            cell!.textLabel!.text = txt as String
            
            var allFiles = 0.0
            var countAllTxt = 0.0
            var thisTxt  = 0.0
            
            for path in paths {
                allFiles++
                if path.hasSuffix(".txt") {
                    countAllTxt++
                }
                if allFiles == Double(indexPath.row) {
                    thisTxt = countAllTxt
                }
            }
            
            cell!.backgroundColor = UIColor(white: CGFloat(0.5 * divide(thisTxt, right: countAllTxt)), alpha: 1)
            cell!.textLabel!.textColor = UIColor.whiteColor()
            cell!.layoutMargins = UIEdgeInsetsZero
            
            return cell!
        }
        
        return UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Error")
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.paths[indexPath.row].hasSuffix(".jpg") ? 320 : 80 //large if image, small if text
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let cell = sender as! UITableViewCell
        let path = paths[previewTable.indexPathForCell(cell)!.row]
        
        if path.hasSuffix(".jpg") {
            var imageViewer = segue.destinationViewController as! ImageViewController
            imageViewer.addMainImage(path)
        } else if path.hasSuffix(".txt") {
            var textViewer  = segue.destinationViewController as! TextViewController
            textViewer.addTextURL(path)
        }
    }
    
    //UITableView delegate method, what to do after side-swiping cell
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        //cdeleting action
        var faveAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default,
            title: "Delete",
            handler: {
                void in
                let path = self.paths[indexPath.row]
                NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
                self.paths.removeAtIndex(indexPath.row)
                
                self.previewTable.beginUpdates()
                self.previewTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Right)
                self.previewTable.endUpdates()
        })
        faveAction.backgroundColor = UIColor(red:1, green:0, blue:0, alpha:1)
        return [faveAction]
    }
    
    //UITableView delegate method, needed because of bug in iOS 8 for now
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // No statement or algorithm is needed in here. Just the implementation
    }
    
    //UITableView delegate method, creates animation when displaying cell
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        self.animateIn(cell)
    }
    
    func divide (left: Double, right: Double) -> Double {
        return Double(left) / Double(right)
    }
    
    //UITableView delegate method, creates animation when displaying cell
    func animateIn(this : UIView) {
        let init_angle : Double = divide(90*M_PI, right: 180)
        var rotation = CATransform3DMakeRotation(CGFloat(init_angle), 0.0, 0.7, 0.4) as CATransform3D
        rotation.m34 = (-1.0/600.0)
        
        this.layer.shadowColor = UIColor.blackColor().CGColor
        this.layer.shadowOffset = CGSizeMake(10, 10)
        this.layer.opacity = 0
        
        this.layer.transform = rotation
        this.layer.anchorPoint = CGPointMake(0, 0.5)
        
        if this.layer.position.x != 0 {
            this.layer.position = CGPointMake(0, this.layer.position.y);
        }
        
        UIView.beginAnimations("rotation",  context: nil)
        UIView.setAnimationDuration(0.4)
        this.layer.transform = CATransform3DIdentity
        this.layer.opacity = 1
        this.layer.shadowOffset = CGSizeMake(0, 0)
        UIView.commitAnimations()
    }
}

