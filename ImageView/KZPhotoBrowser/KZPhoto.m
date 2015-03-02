//
//  KZPhoto.m
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-9.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import "KZPhoto.h"
#import "SDWebImageDecoder.h"
#import "SDWebImageManager.h"
#import "SDWebImageOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface KZPhoto ()
{
    BOOL _loadingInProgress;
    id <SDWebImageOperation> _webImageOperation;
}

@property (nonatomic,readwrite) UIImage *image;

@end

@implementation KZPhoto

#pragma mark - Class Methods

+ (KZPhoto *)photoWithImage:(UIImage *)image
{
    return [[KZPhoto alloc] initWithImage:image];
}

+ (KZPhoto *)photoWithURL:(NSURL *)url
{
    return [[KZPhoto alloc] initWithURL:url];
}

#pragma mark - Init
- (id)initWithImage:(UIImage *)image
{
    if ((self = [super init]))
    {
        _image = image;
        _photoDownloadState = KZPhotoDownloadStateFinished;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    if ((self = [super init]))
    {
        _photoURL = [url copy];
        _photoDownloadState = KZPhotoDownloadStateNone;
    }
    return self;
}
- (void)loadImage
{
    if (_loadingInProgress)
    {
        return;
    }
    _loadingInProgress = YES;
    if (_image)
    {
        self.photoDownloadState = KZPhotoDownloadStateFinished;
    }
    else if (_photoURL)
    {
        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool
                {
                    ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                    [assetslibrary assetForURL:_photoURL
                                   resultBlock:^(ALAsset *asset){
                                       ALAssetRepresentation *rep = [asset defaultRepresentation];
                                       CGImageRef iref = [rep fullScreenImage];
                                       if (iref) {
                                           self.image = [UIImage imageWithCGImage:iref];
                                       }
                                       dispatch_async(dispatch_get_main_queue(), ^
                                       {
                                           self.photoDownloadState = KZPhotoDownloadStateFinished;
                                           _loadingInProgress = NO;
                                       });
                                   }
                                   failureBlock:^(NSError *error) {
                                       self.image = nil;
                                       dispatch_async(dispatch_get_main_queue(), ^
                                       {
                                           self.photoDownloadState = KZPhotoDownloadStateFailed;
                                           _loadingInProgress = NO;
                                       });
                                   }];
                }
            });
        }
        else if ([_photoURL isFileReferenceURL])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool
                {
                    self.image = [UIImage imageWithContentsOfFile:_photoURL.path];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.photoDownloadState = KZPhotoDownloadStateFinished;
                        if (!self.image) {
                            NSLog(@"Error loading photo from path: %@", _photoURL.path);
                            self.photoDownloadState = KZPhotoDownloadStateFailed;
                        }
                        _loadingInProgress = NO;
                    });
                }
            });
            
        }
        else
        {
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            _webImageOperation = [manager downloadImageWithURL:_photoURL
                                                       options:0
                                                      progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                          if (expectedSize > 0)
                                                          {
                                                              float progress = receivedSize / (float)expectedSize;
                                                              self.downloadProgress = [NSNumber numberWithFloat:progress];
                                                          }
                                                      } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                          self.image = image;
                                                          self.photoDownloadState = KZPhotoDownloadStateFinished;
                                                          if (error) {
                                                              NSLog(@"SDWebImage failed to download image: %@", error);
                                                              self.photoDownloadState = KZPhotoDownloadStateFailed;
                                                          }
                                                          _webImageOperation = nil;
                                                          _loadingInProgress = NO;
                                                      }];
        }
    }
    else
    {
        NSLog(@"No Image and Image URL!");
    }

}
- (void)unloadImage
{
    _loadingInProgress = NO;
    _image = nil;
}
- (void)cancelAnyLoading
{
    if (_webImageOperation)
    {
        [_webImageOperation cancel];
        _loadingInProgress = NO;
        self.downloadProgress = [NSNumber numberWithFloat:0.0];
        self.photoDownloadState = KZPhotoDownloadStateFailed;
    }
}
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"photoDownloadState"] || [theKey isEqualToString:@"downloadProgress"])
    {
        automatic = YES;
    }
    return automatic;
}
@end
