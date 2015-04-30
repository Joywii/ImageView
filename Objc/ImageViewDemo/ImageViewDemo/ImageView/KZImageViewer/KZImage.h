//
//  KZImage.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14/10/22.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _KZImageDownloadState
{
    KZImageDownloadStateNone = 0,
    KZImageDownloadStateStart,
    KZImageDownloadStateRunning,
    KZImageDownloadStateCancel,
    KZImageDownloadStateFailed,
    KZImageDownloadStateFinished
}KZImageDownloadState;

@interface KZImage : UIScrollView

@property (nonatomic, readonly) UIImage  *image;
@property (nonatomic, strong) UIImage  *thumbnailImage;
@property (nonatomic, readonly) NSURL    *imageURL;
@property (nonatomic, strong) UIImageView *srcImageView; //来源view

@property (nonatomic, strong) NSNumber *downloadProgress;//0 - 100
@property (nonatomic, assign) KZImageDownloadState imageDownloadState;

+ (KZImage *)photoWithImage:(UIImage *)image;
+ (KZImage *)photoWithURL:(NSURL *)url;

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;

- (void)loadImage;
- (void)unloadImage;
- (void)cancelAnyLoading;

@end
