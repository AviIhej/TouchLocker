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
    var files = [] as [AnyObject]
    
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
        var adding = UIAlertController(title: "Add to TouchLocker", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        var addText = UIAlertAction(title: "Text Snippet", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.addText()
        }
        var addPhotoFromCamera = UIAlertAction(title: "Photo from Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.addPhotoFromCamera()
        }
        var addPhotoFromAlbum = UIAlertAction(title: "Photo from Album", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.addPhotoFromAlbum()
        }
        var cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        adding.addAction(addText)
        adding.addAction(addPhotoFromCamera)
        adding.addAction(addPhotoFromAlbum)
        adding.addAction(cancel)
        self.presentViewController(adding, animated: true, completion: nil)
    }
    
    //add text snippet to TouchLocker
    func addText() {
        //text snippet
        var addingText = UIAlertController(title: "Text Snippet", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        addingText.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.spellCheckingType = UITextSpellCheckingType.Yes
            textField.autocapitalizationType = UITextAutocapitalizationType.Sentences
            textField.autocorrectionType = UITextAutocorrectionType.Yes
        }
        
        var saveText = UIAlertAction(title: "Save", style: UIAlertActionStyle.Default) { (action) -> Void in
            var note = addingText.textFields?.first! as UITextField
            self.lockText(note.text)
        }
        var cancel   = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)

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
        var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
        var txtPath  = rootDir.stringByAppendingString("/text\(NSDate.timeIntervalSinceReferenceDate()).txt")
        
        text.writeToFile(txtPath,
                        atomically: false,
                          encoding: NSASCIIStringEncoding,
                             error: nil)
        
        self.addedNew("text", atPath: txtPath)
    }
    
    //save camera image and reload
    func lockImage(image : UIImage) {
        var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
        var imgPath  = rootDir.stringByAppendingString("/photo\(NSDate.timeIntervalSinceReferenceDate()).jpg")
        
        var data     = UIImageJPEGRepresentation(image, 1)
        NSFileManager.defaultManager().createFileAtPath(imgPath, contents: data, attributes: nil)
        
        self.addedNew("image", atPath: imgPath)
    }
    
    //save album image and reload
    func lockImageAtURL(imagePath : NSURL) {
        var assetLibrary = ALAssetsLibrary()
        assetLibrary.assetForURL(imagePath, resultBlock: { (asset) in
            var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as NSString
            var imgPath  = rootDir.stringByAppendingString("/photo\(NSDate.timeIntervalSinceReferenceDate()).jpg")
            
            var rep    = asset.defaultRepresentation()
            var buff   = UnsafeMutablePointer<UInt8>.alloc(Int(rep.size()))
            var buffed = rep.getBytes(buff, fromOffset: 0, length: Int(rep.size()), error: nil)
            
            var data   = NSData(bytesNoCopy: buff, length: buffed, freeWhenDone: true)
            NSFileManager.defaultManager().createFileAtPath(imgPath, contents: data, attributes: nil)
            
            //delete old image & complete
            var asset = PHAsset.fetchAssetsWithALAssetURLs([imagePath], options: nil)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                PHAssetChangeRequest.deleteAssets(asset)
            }, completionHandler: { (success, error) -> Void in
                if success {
                    self.addedNew("existing image", atPath: imgPath)
                } else {
                    NSLog("error: \(error.localizedDescription)")
                }
            })
            
            
        }, failureBlock: { (error) in
            NSLog("error: \(error.localizedDescription)")
        })
    }
    
    func addedNew(type: String, atPath path: String) {
        //explicitly exclude item from iCloud backup
        NSURL(fileURLWithPath: path).setResourceValue(NSNumber(bool: true), forKey: NSURLIsExcludedFromBackupKey, error: nil)
        //reload table
        self.previewTable.reloadData()
        
        //help text
        if !NSUserDefaults.standardUserDefaults().boolForKey("HasntDeleted") {
            self.reminderHowToDeleteFromTouchLocker()
        }
    }
    
    func reminderHowToDeleteFromTouchLocker() {
        var alert = UIAlertController(title: "Instructions",
            message: "To remove something from your locker, swipe the item to the left and press delete.",
            preferredStyle: UIAlertControllerStyle.Alert)
        
        var accept = UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasntDeleted")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        alert.addAction(accept)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //camera or album image picker
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
        var mediaType = info[UIImagePickerControllerMediaType] as NSString
        if picker.sourceType == UIImagePickerControllerSourceType.Camera {
            var image = info[UIImagePickerControllerOriginalImage] as UIImage
            lockImage(image)
        }
        else if picker.sourceType == UIImagePickerControllerSourceType.PhotoLibrary {
            var imagePath = info[UIImagePickerControllerReferenceURL] as NSURL
            lockImageAtURL(imagePath)
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.paths.removeAll(keepCapacity: false)
        self.files.removeAll(keepCapacity: false)
        var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir  = rootDir[0] as NSString
        var fileList = NSFileManager.defaultManager().contentsOfDirectoryAtPath(docsDir, error: nil) as [String]
        
        //filter by files
        for filename in fileList {
            var path = "\(docsDir)/\(filename)"
            self.paths.append(path)
            if filename.hasSuffix(".jpg") {
                self.files.append(UIImage(contentsOfFile: path))
            } else if filename.hasSuffix(".txt") {
                self.files.append(NSString(contentsOfFile: path, encoding: NSASCIIStringEncoding, error: nil))
            }
        }

        return self.files.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let img = self.files[indexPath.row] as? UIImage { //image settings
            let imageTableIdentifier: NSString = "ImageTableCell"
            
            var cell = tableView.dequeueReusableCellWithIdentifier(imageTableIdentifier) as? UITableViewCell
            
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
        } else { //text settings
            let textTableIdentifier: NSString  = "TextTableCell"
            
            var cell = tableView.dequeueReusableCellWithIdentifier(textTableIdentifier) as? UITableViewCell
            
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: textTableIdentifier)
            }
            
            cell!.tag = indexPath.row
            
            let txt = self.files[indexPath.row] as? NSString
            
            var preview : String
            if txt!.length > 20 {
                preview = txt!.substringToIndex(20)
            }
            else {
                preview = txt!
            }

            cell!.textLabel!.text = preview
            
            var allFiles = 0.0
            var countAllTxt = 0.0
            var thisTxt  = 0.0
            for path in self.paths {
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
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.paths[indexPath.row].hasSuffix(".jpg") ? 320 : 80 //large if image, small if text
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        var cell = sender as UITableViewCell
        
        if self.paths[cell.tag].hasSuffix(".jpg") {
            var imageViewer = segue.destinationViewController as ImageViewController
            imageViewer.setMainImage(self.paths[cell.tag])
        } else if self.paths[cell.tag].hasSuffix(".txt") {
            var textViewer  = segue.destinationViewController as TextViewController
            textViewer.setTextURL(self.paths[cell.tag], text: self.files[cell.tag] as NSString)
        }
    }
    
    //UITableView delegate method, what to do after side-swiping cell
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
            //cdeleting action
            var faveAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default,
                title: "Delete",
                handler: {
                    void in
                    var cell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!

                    NSFileManager.defaultManager().removeItemAtPath(self.paths[cell.tag], error: nil)
                    self.paths.removeAtIndex(cell.tag)
                    self.files.removeAtIndex(cell.tag)
                    
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
        var init_angle : Double = divide(90*M_PI, right: 180)
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

