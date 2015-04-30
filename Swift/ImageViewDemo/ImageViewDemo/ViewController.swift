//
//  ViewController.swift
//  ImageViewDemo
//
//  Created by joywii on 15/4/29.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

import UIKit

let kScreenHeight = UIScreen.mainScreen().bounds.size.height
let kScreenWidth = UIScreen.mainScreen().bounds.size.width

class ViewController: UIViewController {
    
    var firstImageArray : NSMutableArray?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.whiteColor()
        self.navigationItem.title = "ImageView"
        
        self.firstImageArray = NSMutableArray()
        
        var viewImageLabel = UILabel(frame: CGRectMake(10, 100,kScreenWidth - 20, 20))
        viewImageLabel.backgroundColor = UIColor.clearColor()
        viewImageLabel.text = "方式一："
        viewImageLabel.font = UIFont.systemFontOfSize(17)
        viewImageLabel.textColor = UIColor.blackColor()
        self.view.addSubview(viewImageLabel)
        
        var width = (kScreenWidth - 40) / 3
        
        for var i : CGFloat = 0 ; i < 3 ; i++ {
            var x : CGFloat = 10
            var y : CGFloat = 130
            x += (i * (10 + width))
            
            var imageView = UIImageView(frame: CGRectMake(x, y, width, width))
            self.firstImageArray!.addObject(imageView)
            imageView.image = UIImage(named: "\(Int(i+1)).jpg")
            imageView.userInteractionEnabled = true
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            
            var gesture = UITapGestureRecognizer(target: self, action: "firstTapHandle:")
            imageView.addGestureRecognizer(gesture)
            self.view.addSubview(imageView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func firstTapHandle(tap:UITapGestureRecognizer) {
        var currentImageView = tap.view as! UIImageView
        var currentImage = currentImageView.image
        if currentImage == nil {
            return
        }
        var kzImageArray = NSMutableArray()
        for var i = 0 ;i < self.firstImageArray?.count; i++ {
            var imageView = self.firstImageArray?.objectAtIndex(i) as! UIImageView
            var kzImage : KZImage = KZImage(image: imageView.image!)
            kzImage.thumbnailImage = imageView.image
            
            kzImage.srcImageView = imageView
            kzImageArray.addObject(kzImage)
        }
        var imageViewer = KZImageViewer(frame: CGRectMake(0, 0, kScreenWidth, kScreenHeight))
        
        imageViewer.showImages(kzImageArray as NSArray, index: self.firstImageArray!.indexOfObject(currentImageView))
    }

}

