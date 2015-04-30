//
//  KZImageViewer.swift
//  ImageViewDemo
//
//  Created by joywii on 15/4/30.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

import UIKit

let kPadding = 10

class KZImageViewer: UIView , UIScrollViewDelegate ,KZImageScrollViewDelegate{
    
    private var scrollView : UIScrollView?
    private var selectIndex : NSInteger?
    private var scrollImageViewArray : NSMutableArray?
    private var selectImageView : UIImageView?
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.setupUI()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        self.backgroundColor = UIColor.blackColor()
        self.scrollImageViewArray = NSMutableArray()
        
        self.scrollView = UIScrollView(frame: self.frameForPagingScrollView())
        self.scrollView?.pagingEnabled = true
        self.scrollView?.showsHorizontalScrollIndicator = false
        self.scrollView?.showsVerticalScrollIndicator = false
        self.scrollView?.backgroundColor = UIColor.clearColor()
        self.scrollView?.delegate = self
        self.addSubview(self.scrollView!)
    }
    
    func showImages(imageArray:NSArray,index:NSInteger) {
        self.alpha = 0.0
        var window : UIWindow = UIApplication.sharedApplication().keyWindow!
        window.addSubview(self)
        
        let currentPage = index
        self.selectIndex = index

        var kzSelectImage : KZImage = imageArray.objectAtIndex(Int(index)) as! KZImage
        var selectImage : UIImage? = SDImageCache.sharedImageCache().imageFromDiskCacheForKey(kzSelectImage.imageUrl?.absoluteString)
        if(selectImage == nil) {
            selectImage = kzSelectImage.thumbnailImage
        }
        var selectImageView : UIImageView = kzSelectImage.srcImageView!
        self.scrollView?.contentSize = CGSizeMake(self.scrollView!.bounds.size.width * CGFloat(imageArray.count), self.scrollView!.bounds.size.height)
        self.scrollView?.contentOffset = CGPointMake(CGFloat(currentPage) * self.scrollView!.bounds.size.width,0)
        
        //动画
        var selectImageViewFrame = window.convertRect(selectImageView.frame, fromView: selectImageView.superview)
        var imageView = UIImageView(frame: selectImageViewFrame)
        imageView.contentMode = selectImageView.contentMode
        imageView.clipsToBounds = true
        imageView.image = selectImage
        imageView.backgroundColor = UIColor.clearColor()
        imageView.userInteractionEnabled = true
        
        window.addSubview(imageView)
        
        let fullWidth = window.frame.size.width
        let fullHeight = window.frame.size.height
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            
            self.alpha = 1.0
            imageView.transform = CGAffineTransformIdentity
            var size = imageView.image != nil ? imageView.image?.size : imageView.frame.size
            var ratio = min(fullWidth / size!.width,fullHeight / size!.height)
            var w = ratio > 1 ? size!.width : ratio * size!.width
            var h = ratio > 1 ? size!.height : ratio * size!.height
            imageView.frame = CGRectMake((fullWidth - w) / 2, (fullHeight - h) / 2, w, h)
            
        }) { (finished) -> Void in
            for(var i = 0 ; i < imageArray.count ; i++) {
                var kzImage:KZImage = imageArray.objectAtIndex(i) as! KZImage
                var zoomImageView = KZImageScrollView(frame: self.frameForPageAtIndex(UInt(i)))
                zoomImageView.kzImage = kzImage
                zoomImageView.imageDelegate = self
                zoomImageView.userInteractionEnabled = true
                
                if(i == Int(currentPage)){
                    if(kzImage.image == nil) {
                        zoomImageView.startLoadImage()
                    }
                }
                self.scrollView?.addSubview(zoomImageView)
                self.scrollImageViewArray?.addObject(zoomImageView)
            }
            self.preLoadImage(currentPage)
            imageView.removeFromSuperview()
        }
    }
    func showImages(imageArray:NSArray,selectImageView:UIImageView,index:NSInteger) {
        self.alpha = 0.0
        var window : UIWindow = UIApplication.sharedApplication().keyWindow!
        window.addSubview(self)
        
        let currentPage = index
        self.selectIndex = index
        self.selectImageView = selectImageView
        self.scrollView?.contentSize = CGSizeMake(self.scrollView!.bounds.size.width * CGFloat(imageArray.count), self.scrollView!.bounds.size.height)
        self.scrollView?.contentOffset = CGPointMake(CGFloat(currentPage) * self.scrollView!.bounds.size.width,0)
        
        //动画
        var selectImageViewFrame = window.convertRect(selectImageView.frame, fromView: selectImageView.superview)
        var imageView = UIImageView(frame: selectImageViewFrame)
        imageView.contentMode = selectImageView.contentMode
        imageView.clipsToBounds = true
        imageView.image = selectImageView.image
        imageView.backgroundColor = UIColor.clearColor()
        imageView.userInteractionEnabled = true
        
        window.addSubview(imageView)
        
        let fullWidth = window.frame.size.width
        let fullHeight = window.frame.size.height
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            
            self.alpha = 1.0
            imageView.transform = CGAffineTransformIdentity
            var size = imageView.image != nil ? imageView.image?.size : imageView.frame.size
            var ratio = min(fullWidth / size!.width,fullHeight / size!.height)
            var w = ratio > 1 ? size!.width : ratio * size!.width
            var h = ratio > 1 ? size!.height : ratio * size!.height
            imageView.frame = CGRectMake((fullWidth - w) / 2, (fullHeight - h) / 2, w, h)
            
            }) { (finished) -> Void in
                for(var i = 0 ; i < imageArray.count ; i++) {
                    var kzImage:KZImage = imageArray.objectAtIndex(i) as! KZImage
                    var zoomImageView = KZImageScrollView(frame: self.frameForPageAtIndex(UInt(i)))
                    zoomImageView.kzImage = kzImage
                    zoomImageView.imageDelegate = self
                    zoomImageView.userInteractionEnabled = true
                    
                    if(i == Int(currentPage)){
                        if(kzImage.image == nil) {
                            zoomImageView.startLoadImage()
                        }
                    }
                    self.scrollView?.addSubview(zoomImageView)
                    self.scrollImageViewArray?.addObject(zoomImageView)
                }
                self.preLoadImage(currentPage)
                imageView.removeFromSuperview()
        }
    }
    private func tappedScrollView(tap:UITapGestureRecognizer) {
        self.hide()
    }
    private func hide() {
        for imageView in self.scrollImageViewArray as NSArray? as! [KZImageScrollView] {
            imageView.cancelLoadImage()
            imageView.removeFromSuperview()
        }
        var window : UIWindow = UIApplication.sharedApplication().keyWindow!
        
        let fullWidth = window.frame.size.width
        let fullHeight = window.frame.size.height
        
        var index = self.pageIndex()
        var zoomImageView = self.scrollImageViewArray?.objectAtIndex(Int(index)) as! KZImageScrollView
        
        var size = zoomImageView.kzImage?.image != nil ? zoomImageView.kzImage?.image?.size : zoomImageView.frame.size
        var ratio = min(fullWidth / size!.width, fullHeight / size!.height)
        var w = ratio > 1 ? size!.width : ratio*size!.width
        var h = ratio > 1 ? size!.height : ratio*size!.height
        var frame = CGRectMake((fullWidth - w) / 2, (fullHeight - h) / 2, w, h)
        
        var imageView = UIImageView(frame: frame)
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = zoomImageView.kzImage!.image
        imageView.backgroundColor = UIColor.clearColor()
        imageView.userInteractionEnabled = true
        
        window.addSubview(imageView)
        
        var selectImageViewFrame = window.convertRect(zoomImageView.kzImage!.srcImageView!.frame, fromView: zoomImageView.kzImage!.srcImageView!.superview)
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            
            self.alpha = 0.0
            imageView.frame = selectImageViewFrame
        }) { (finished) -> Void in
            for imageView in self.scrollImageViewArray as NSArray? as! [KZImageScrollView] {
                SDImageCache.sharedImageCache().removeImageForKey(imageView.kzImage?.imageUrl?.absoluteString, fromDisk: false)
            }
            imageView.removeFromSuperview()
            self.removeFromSuperview()
        }
    }
    private func pageIndex() -> NSInteger{
        return NSInteger(self.scrollView!.contentOffset.x / self.scrollView!.frame.size.width)
    }
    private func frameForPagingScrollView() -> CGRect {
        var frame = self.bounds
        frame.origin.x -= CGFloat(kPadding)
        frame.size.width += 2 * CGFloat(kPadding)
        return CGRectIntegral(frame)
    }
    private func frameForPageAtIndex(index:UInt) -> CGRect {
        var bounds = self.scrollView?.bounds
        var pageFrame = bounds
        pageFrame?.size.width -= (2*CGFloat(kPadding))
        pageFrame?.origin.x = (bounds!.size.width * CGFloat(index)) + CGFloat(kPadding)
        return CGRectIntegral(pageFrame!)
    }
    func imageScrollViewSingleTap(imageScrollView: KZImageScrollView) {
        self.hide()
    }
    func preLoadImage(currentIndex:NSInteger) {
        var preIndex = currentIndex - 1
        if(preIndex > 1) {
            var preZoomImageView: KZImageScrollView = self.scrollImageViewArray!.objectAtIndex(Int(preIndex)) as! KZImageScrollView
            preZoomImageView.startLoadImage()
        }
        var nextIndex = currentIndex + 1
        if(nextIndex < self.scrollImageViewArray?.count) {
            var nextZoomImageView: KZImageScrollView = self.scrollImageViewArray!.objectAtIndex(Int(nextIndex)) as! KZImageScrollView
            nextZoomImageView.startLoadImage()
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        var index = self.pageIndex()
        var zoomImageView : KZImageScrollView = self.scrollImageViewArray?.objectAtIndex(Int(index)) as! KZImageScrollView
        zoomImageView.startLoadImage()
        self.preLoadImage(index)
    }
}
