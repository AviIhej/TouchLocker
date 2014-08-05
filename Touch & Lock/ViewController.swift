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

class ViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var imgTable : UITableView!
    var jpegs : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func copyFileFromLibrary(sender : UIBarButtonItem) {
        var imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePickerController.delegate   = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    @IBAction func addFileFromCamera(sender: UIBarButtonItem) {
        var imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
        imagePickerController.delegate   = self
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }

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
    
    func lockImage(image : UIImage) {
        var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir  = rootDir[0] as NSString
        var fileList = NSFileManager.defaultManager().contentsOfDirectoryAtPath(docsDir, error: nil)
        var imgPath  = docsDir.stringByAppendingString("/photo\(fileList.count+1).jpg")
        
        var data     = UIImageJPEGRepresentation(image, 1)
        NSFileManager.defaultManager().createFileAtPath(imgPath, contents: data, attributes: nil)
        
        self.imgTable.reloadData()
    }
    
    func lockImageAtURL(imagePath : NSURL) {
        var assetLibrary = ALAssetsLibrary()
        assetLibrary.assetForURL(imagePath, resultBlock: { (asset) in
            var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            var docsDir  = rootDir[0] as NSString
            var fileList = NSFileManager.defaultManager().contentsOfDirectoryAtPath(docsDir, error: nil)
            var imgPath  = docsDir.stringByAppendingString("/photo\(fileList.count+1).jpg")
            
            var rep    = asset.defaultRepresentation()
            var buff   = UnsafeMutablePointer<UInt8>.alloc(Int(rep.size()))
            var buffed = rep.getBytes(buff, fromOffset: 0, length: Int(rep.size()), error: nil)
            
            var data   = NSData(bytesNoCopy: buff, length: buffed, freeWhenDone: true)
            NSFileManager.defaultManager().createFileAtPath(imgPath, contents: data, attributes: nil)
            
            self.imgTable.reloadData()
        }, failureBlock: { (error) in
            NSLog("error: \(error.localizedDescription)")
        })
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        self.jpegs = []
        var rootDir  = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir  = rootDir[0] as NSString
        var fileList = NSFileManager.defaultManager().contentsOfDirectoryAtPath(docsDir, error: nil) as [String]
        
        //filter by jpegs
        for file in fileList {
            if file.hasSuffix(".jpg") {
                self.jpegs.append(file)
            }
        }

        return self.jpegs.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let simpleTableIdentifier: NSString = "SimpleTableCell"
        
        var cell : UITableViewCell = tableView.dequeueReusableCellWithIdentifier(simpleTableIdentifier) as UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: simpleTableIdentifier)
        }
        cell.tag = indexPath.row
        
        var rootDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir = rootDir[0] as NSString
        var imgPath = docsDir.stringByAppendingString("/\(self.jpegs[indexPath.row])")
        
        var image = UIImage(contentsOfFile: imgPath)
        var imageView = UIImageView(image: image)
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        cell.backgroundView = imageView
        
        return cell;
    }
    
    override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 320
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        var imageViewer = segue.destinationViewController as ImageViewController
        var cell        = sender as UITableViewCell

        var rootDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        var docsDir = rootDir[0] as NSString
        var imgPath = docsDir.stringByAppendingString("/\(self.jpegs[cell.tag])")
        imageViewer.setMainImage(imgPath)
    }
    
    //UITableView delegate method, what to do after side-swiping cell
    override func tableView(tableView: UITableView!, editActionsForRowAtIndexPath indexPath: NSIndexPath!) -> [AnyObject]! {
            //create favoriting action
            var faveAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default,
                title: "Delete",
                handler: {
                    void in
                    var cell    = tableView.cellForRowAtIndexPath(indexPath)
                    var rootDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                    var docsDir = rootDir[0] as NSString
                    var imgPath = docsDir.stringByAppendingString("/\(self.jpegs[cell.tag])")
                    NSFileManager.defaultManager().removeItemAtPath(imgPath, error: nil)
                    self.jpegs.removeAtIndex(cell.tag)
                    tableView.reloadData()
            })
            faveAction.backgroundColor = UIColor(red:1, green:0, blue:0, alpha:1)
            return [faveAction]

    }
    
    //UITableView delegate method, needed because of bug in iOS 8 for now
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // No statement or algorithm is needed in here. Just the implementation
    }
    
    //UITableView delegate method, creates animation when displaying cell
    override func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!) {
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
        UIView.setAnimationDuration(0.8)
        this.layer.transform = CATransform3DIdentity
        this.layer.opacity = 1
        this.layer.shadowOffset = CGSizeMake(0, 0)
        UIView.commitAnimations()
    }
}
