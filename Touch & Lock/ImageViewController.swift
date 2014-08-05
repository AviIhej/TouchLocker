//
//  ImageViewController.swift
//  TouchLocker
//
//  Created by Ruben on 8/4/14.
//  Copyright (c) 2014 Ruben. All rights reserved.
//

import UIKit

class ImageViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var mainImageView: UIImageView!
    var mainImage : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let image = mainImage {
            self.mainImageView.frame = self.scrollView.bounds
            self.mainImageView.center = CGPointMake(CGRectGetMidX(self.scrollView.bounds), CGRectGetMidY(self.scrollView.bounds))
            self.mainImageView.image = image
        }
        
        self.scrollView.clipsToBounds = true
        self.scrollView.contentSize = self.mainImageView.bounds.size
        self.scrollView.zoomScale = 1.0
        self.scrollView.maximumZoomScale = 5.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setMainImage(path : String) {
        self.mainImage = UIImage(contentsOfFile: path)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView!) {

    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView!) -> UIView! {
        return self.mainImageView
    }
}