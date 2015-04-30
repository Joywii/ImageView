//
//  KZPhoto.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-9.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum _KZPhotoDownloadState
{
    KZPhotoDownloadStateNone = 0,
    KZPhotoDownloadStateStart,
    KZPhotoDownloadStateRunning,
    KZPhotoDownloadStateCancel,
    KZPhotoDownloadStateFailed,
    KZPhotoDownloadStateFinished
}KZPhotoDownloadState;

@interface KZPhoto : NSObject

@property (nonatomic, readonly) UIImage  *image;
@property (nonatomic, readonly) NSURL    *photoURL;

@property (nonatomic, strong) NSNumber *downloadProgress;//0 - 100
@property (nonatomic, assign) KZPhotoDownloadState photoDownloadState;

+ (KZPhoto *)photoWithImage:(UIImage *)image;
+ (KZPhoto *)photoWithURL:(NSURL *)url;

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;

- (void)loadImage;
- (void)unloadImage;
- (void)cancelAnyLoading;

@end
