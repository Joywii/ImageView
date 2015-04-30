//
//  KZTapDetecingImageView.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-10.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KZTapDetectingImageViewDelegate;

@interface KZTapDetectingImageView : UIImageView
{
}

@property (nonatomic, weak) id <KZTapDetectingImageViewDelegate> tapDelegate;

@end

@protocol KZTapDetectingImageViewDelegate <NSObject>

@optional

- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView tripleTapDetected:(UITouch *)touch;

@end
