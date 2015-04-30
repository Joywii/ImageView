//
//  KZImageScrollView.swift
//  ImageViewDemo
//
//  Created by joywii on 15/4/29.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

import UIKit

protocol KZImageScrollViewDelegate : NSObjectProtocol {
    func imageScrollViewSingleTap(imageScrollView:KZImageScrollView) -> Void
}

class KZImageScrollView: UIScrollView ,UIScrollViewDelegate {
    
    var kzImage : KZImage? {
        willSet {
            if(kzImage != newValue) {
                if(self.kzImage != nil && newValue == nil) {
                    if(self.kzImage!.respondsToSelector("cancelAnyLoading")) {
                        
                    }
                }
            }
            if self.kzImage != nil {
                self.kzImage!.removeObserver(self, forKeyPath: "imageDownloadState")
                self.kzImage!.removeObserver(self, forKeyPath: "downloadProgress")
            }
        }
        didSet {
            self.kzImage!.addObserver(self, forKeyPath: "imageDownloadState", options: .New | .Old, context: nil)
            self.kzImage!.addObserver(self, forKeyPath: "downloadProgress", options: .New | .Old, context: nil)
            if(self.kzImage != nil) {
                self.displayImage()
            }
        }
    }
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if (keyPath == "imageDownloadState") {
            let number : NSNumber = change[NSKeyValueChangeNewKey] as! NSNumber
            let imageDownloadState = KZImageDownloadState(rawValue: UInt(number.integerValue))
            if (imageDownloadState == .Finished) {
                self.displayImage()
            }
        }
        if (keyPath == "downloadProgress") {
            var progress : NSNumber = self.kzImage?.valueForKey("downloadProgress") as! NSNumber
            self.progressView.progress = CGFloat(max(min(1,progress.floatValue), 0))
        }
    }
    
    var imageDelegate : KZImageScrollViewDelegate?
    
    private var photoImageView : UIImageView
    private var progressView : DACircularProgressView
    
    deinit {
        if(self.kzImage != nil) {
            self.kzImage!.removeObserver(self, forKeyPath: "imageDownloadState")
            self.kzImage!.removeObserver(self, forKeyPath: "downloadProgress")
        }
    }
    override init(frame: CGRect) {
        self.photoImageView = UIImageView(frame: CGRectZero)
        self.photoImageView.contentMode = UIViewContentMode.Center
        self.photoImageView.backgroundColor = UIColor.blackColor()
        
        self.progressView = DACircularProgressView(frame: CGRectZero)
        self.progressView.userInteractionEnabled = false
        self.progressView.thicknessRatio = 0.1
        self.progressView.roundedCorners = 0
        self.progressView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin | UIViewAutoresizing.FlexibleRightMargin
        
        super.init(frame: frame)
        
        self.addSubview(self.photoImageView)
        self.progressView.frame = CGRectMake(self.bounds.size.width / 2 - 20, self.bounds.size.height / 2 - 20, 40, 40)
        self.addSubview(self.progressView)
        
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clearColor()
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.decelerationRate = UIScrollViewDecelerationRateFast
        self.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        var singleTap = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        singleTap.delaysTouchesBegan = true
        singleTap.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTap)
        
        var doubleTap = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
        
        singleTap.requireGestureRecognizerToFail(doubleTap)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startLoadImage() {
        if(self.kzImage?.image == nil) {
            self.showLoadingIndicator()
            self.kzImage?.loadImage()
        }
    }
    func cancelLoadImage() {
        self.kzImage?.cancelAnyLoading()
    }
    func handleSingleTap(tap:UITapGestureRecognizer) -> Void {
        if (self.zoomScale != self.minimumZoomScale) {
            self.setZoomScale(self.minimumZoomScale, animated: false)
        }
        if ((self.imageDelegate != nil) && (self.imageDelegate!.respondsToSelector("imageScrollViewSingleTap:"))) {
            self.imageDelegate!.imageScrollViewSingleTap(self)
        }
    }
    func handleDoubleTap(tap:UITapGestureRecognizer) -> Void {
        let touchPoint = tap.locationInView(self)
        if (self.zoomScale != self.minimumZoomScale) {
            self.setZoomScale(self.minimumZoomScale, animated: true)
        } else {
            let newZoomScale = (self.maximumZoomScale + self.minimumZoomScale) / 2.0
            let xsize = self.bounds.size.width / newZoomScale
            let ysize = self.bounds.size.height / newZoomScale
            self.zoomToRect(CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize), animated: true)
        }
    }
    private func hideLoadingIndicator() {
        self.progressView.hidden = true
    }
    private func showLoadingIndicator() {
        self.zoomScale = 0
        self.minimumZoomScale = 0
        self.maximumZoomScale = 0
        self.progressView.progress = 0
        self.progressView.hidden = false
    }
    private func displayImage() {
        if(self.kzImage != nil) {
            self.maximumZoomScale = 1
            self.minimumZoomScale = 1
            self.zoomScale = 1
            self.contentSize = CGSizeMake(0, 0)
            
            var img:UIImage?
            if(self.kzImage?.image != nil) {
                img = self.kzImage?.image
            } else {
                img = self.kzImage?.thumbnailImage
            }
            if(img != nil) {
                self.hideLoadingIndicator()
                self.photoImageView.image = img
                self.photoImageView.hidden = false
                
                var photoImageViewFrame = CGRect(origin: CGPointZero, size: img!.size)
                self.photoImageView.frame = photoImageViewFrame
                self.contentSize = photoImageViewFrame.size
                self.setMaxMinZoomScalesForCurrentBounds()
            }
            self.setNeedsDisplay()
        }
    }
    /*
    * 设置图片的放大和缩小参数
    */
    private func setMaxMinZoomScalesForCurrentBounds() {
        self.maximumZoomScale = 1
        self.minimumZoomScale = 1
        self.zoomScale = 1
        
        if(self.photoImageView.image == nil) {
            return
        }
        self.photoImageView.frame = CGRectMake(0, 0, self.photoImageView.frame.size.width, self.photoImageView.frame.size.height)
        
        let boundsSize = self.bounds.size
        let imageSize = self.photoImageView.frame.size
        
        let xScale = boundsSize.width / imageSize.width
        let yScale = boundsSize.height / imageSize.height
        var minScale = min(xScale, yScale)
        
        let maxScale : CGFloat = 2.0
        
        if (xScale >= 1.0 && yScale >= 1.0) {
            minScale = 1.0
        }
        
        self.maximumZoomScale = maxScale
        self.minimumZoomScale = minScale
        self.zoomScale = minScale
        
        self.setNeedsDisplay()
    }
    override func layoutSubviews() {
        if (!self.progressView.hidden) {
            var x : Float = floorf(Float((self.bounds.size.width - self.progressView.frame.size.width) / 2.0))
            var y : Float = floorf(Float((self.bounds.size.height - self.progressView.frame.size.height) / 2.0))
            self.progressView.frame = CGRectMake(CGFloat(x),CGFloat(y), self.progressView.frame.size.width, self.progressView.frame.size.height)
        }
        super.layoutSubviews()
        
        let boundsSize = self.bounds.size
        var frameToCenter = self.photoImageView.frame
        
        //水平
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / 2.0)
        } else {
            frameToCenter.origin.x = 0
        }
        //垂直
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / 2.0)
        } else {
            frameToCenter.origin.y = 0
        }
        if (!CGRectEqualToRect(self.photoImageView.frame, frameToCenter)) {
            self.photoImageView.frame = frameToCenter
        }
    }
    
    //ScrollView Delegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.photoImageView
    }
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView!) {
        self.scrollEnabled = true
    }
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.setNeedsLayout()
        self.setNeedsDisplay()
    }
}
