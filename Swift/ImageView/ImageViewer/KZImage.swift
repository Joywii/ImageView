//
//  KZImage.swift
//  ImageViewDemo
//
//  Created by joywii on 15/4/29.
//  Copyright (c) 2015年 joywii. All rights reserved.
//
import UIKit
import AssetsLibrary

enum KZImageDownloadState : UInt {
    case None = 0
    case Start
    case Running
    case Cancel
    case Failed
    case Finished
}

class KZImage: UIScrollView {

    var image : UIImage?
    var thumbnailImage : UIImage?
    var imageUrl : NSURL?
    var srcImageView : UIImageView?
    
    dynamic var downloadProgress : NSNumber = 0
    var imageDownloadState = KZImageDownloadState.None {
        didSet {
            self.imageDownloadSateRaw = imageDownloadState.rawValue
        }
    }
    dynamic private(set) var imageDownloadSateRaw : UInt  = 0
    
    private var loadingInProgress = false
    private var webImageOperation : SDWebImageOperation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(image:UIImage) {
        self.init(frame: CGRectZero)
        self.image = image
    }
    convenience init(url:NSURL) {
        self.init(frame: CGRectZero)
        self.imageUrl = url
    }
    class func photoWithImage(image:UIImage) -> KZImage {
        return KZImage(image: image)
    }
    class func photoWithUrl(url:NSURL) -> KZImage {
        return KZImage(url: url)
    }
    func loadImage() {
        if(self.loadingInProgress) {
            return
        }
        self.loadingInProgress = true
        if(self.image != nil) {
            self.imageDownloadState = KZImageDownloadState.Finished
        } else if (self.imageUrl != nil) {
            if(self.imageUrl?.scheme?.lowercaseString == "assets-library") {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    autoreleasepool {
                        var assetslibrary = ALAssetsLibrary()
                        assetslibrary.assetForURL(self.imageUrl!, resultBlock: { (asset: ALAsset?) -> Void in
                            let rep = asset!.defaultRepresentation()
                            self.image = UIImage(CGImage: rep.fullScreenImage().takeUnretainedValue())
                            dispatch_async(dispatch_get_main_queue(), {
                                self.imageDownloadState = KZImageDownloadState.Finished
                                self.srcImageView!.image = self.image
                                self.loadingInProgress = false
                            })
                        }, failureBlock: { (error : NSError?) -> Void in
                            self.image = nil
                            dispatch_async(dispatch_get_main_queue(), {
                                self.imageDownloadState = KZImageDownloadState.Failed
                                self.loadingInProgress = false
                            })
                        })
                    }
                })
            } else if(self.imageUrl!.isFileReferenceURL()) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    autoreleasepool{
                        self.image = UIImage(contentsOfFile: self.imageUrl!.path!)
                        dispatch_async(dispatch_get_main_queue(), {
                            if(self.image == nil) {
                                println("Error loading photo from path:\(self.imageUrl!.path)")
                                self.imageDownloadState = KZImageDownloadState.Failed
                            } else {
                                self.imageDownloadState = KZImageDownloadState.Finished
                                self.srcImageView!.image = self.image!
                            }
                            self.loadingInProgress = false
                        })
                    }
                })
            } else {
                var manager = SDWebImageManager.sharedManager()
                self.webImageOperation = manager.downloadImageWithURL(self.imageUrl!, options: SDWebImageOptions.RetryFailed, progress: { (receivedSize, expectedSize) -> Void in
                    if (expectedSize > 0) {
                        var progress : Float = Float(receivedSize) / Float(expectedSize)
                        self.downloadProgress = NSNumber(float: progress)
                    }
                }, completed: { (image,error,cacheType,finished,imageUrl) -> Void in
                    self.image = image
                    if(error != nil) {
                        self.imageDownloadState = KZImageDownloadState.Failed
                    }
                    self.webImageOperation = nil
                    self.loadingInProgress = false
                })
            }
        } else {
            println("No Image or Image Url!")
        }
    }
    func unloadImage() {
        self.loadingInProgress = false
        self.image = nil
    }
    func cancelAnyLoading() {
        if (self.webImageOperation != nil) {
            self.webImageOperation!.cancel()
            self.loadingInProgress = false
            self.downloadProgress = NSNumber(float: 0)
            self.imageDownloadState = KZImageDownloadState.Failed
        }
    }
}
