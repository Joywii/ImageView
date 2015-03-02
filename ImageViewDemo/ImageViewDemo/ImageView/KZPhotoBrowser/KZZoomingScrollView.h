//
//  KZZoomingScrollView.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-10.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KZPhoto.h"
#import "KZPhotoBrowser.h"


@interface KZZoomingScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) KZPhoto *photo;

- (id)initWithPhotoBrowser:(KZPhotoBrowser *)browser;
- (void)displayImage;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end
