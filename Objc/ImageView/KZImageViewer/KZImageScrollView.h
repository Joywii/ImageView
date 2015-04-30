//
//  KZImageScrollView.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14/10/22.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KZImage.h"


@class KZImageScrollView;

@protocol KZImageScrollViewDelegate <NSObject>

- (void)imageScrollViewSingleTap:(KZImageScrollView *)imageScrollView;

@end

@interface KZImageScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, strong) KZImage *kzImage;
@property (nonatomic, weak) id<KZImageScrollViewDelegate> imageDelegate;

- (void)startLoadImage;
- (void)cancelLoadImage;

@end
