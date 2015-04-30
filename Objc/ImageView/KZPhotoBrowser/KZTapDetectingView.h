//
//  KZTapDetectingView.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-10.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol KZTapDetectingViewDelegate;

@interface KZTapDetectingView : UIView {}

@property (nonatomic, weak) id <KZTapDetectingViewDelegate> tapDelegate;

@end

@protocol KZTapDetectingViewDelegate <NSObject>

@optional

- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch;
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch;
- (void)view:(UIView *)view tripleTapDetected:(UITouch *)touch;

@end