//
//  ImageViewController.swift
//  TouchLocker
//
//  Created by Ruben on 8/4/14.
//  Copyright (c) 2014 Ruben. All rights reserved.
//

import UIKit

class ImageViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var mainImageView: UIImageView!
    var mainImageURL : NSURL?
    var mainImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        if let image = mainImage {
            self.mainImageView.image = image
            self.mainImageView.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if let image = mainImage {
            var ratio = CGRectGetWidth(self.scrollView.bounds) / image.size.width
            self.mainImageView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), image.size.height * ratio)
            self.mainImageView.center = CGPointMake(CGRectGetMidX(self.scrollView.bounds), CGRectGetMidY(self.scrollView.bounds))
            self.mainImageView.hidden = false
        }
        
        self.scrollView.clipsToBounds = true
        self.scrollView.contentSize = self.mainImageView.bounds.size
        self.scrollView.zoomScale = 1.0
        self.scrollView.maximumZoomScale = 10.0
        
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func shareExternal(sender: AnyObject) {
        var items = [AnyObject]()
        items.append(mainImageURL!)
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    func setMainImage(path : String) {
        self.mainImageURL = NSURL(fileURLWithPath: path)
        self.mainImage    = UIImage(contentsOfFile: path)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView!) -> UIView! {
        return self.mainImageView
    }
}