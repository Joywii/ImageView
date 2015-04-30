//
//  KZImage.m
//  KuaiZhanNativeApp
//
//  Created by joywii on 14/10/22.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import "KZImage.h"
#import "SDWebImageDecoder.h"
#import "SDWebImageManager.h"
#import "SDWebImageOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface KZImage ()
{
    BOOL _loadingInProgress;
    id <SDWebImageOperation> _webImageOperation;
}

@property (nonatomic,readwrite) UIImage *image;

@end

@implementation KZImage

#pragma mark - Class Methods

+ (KZImage *)photoWithImage:(UIImage *)image
{
    return [[KZImage alloc] initWithImage:image];
}

+ (KZImage *)photoWithURL:(NSURL *)url
{
    return [[KZImage alloc] initWithURL:url];
}

#pragma mark - Init
- (id)initWithImage:(UIImage *)image
{
    if ((self = [super init]))
    {
        _image = image;
        _imageDownloadState = KZImageDownloadStateFinished;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    if ((self = [super init]))
    {
        _imageURL = [url copy];
        //_image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:url.absoluteString];
        _imageDownloadState = KZImageDownloadStateNone;
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
        self.imageDownloadState = KZImageDownloadStateFinished;
    }
    else if (_imageURL)
    {
        if ([[[_imageURL scheme] lowercaseString] isEqualToString:@"assets-library"])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool
                {
                    ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                    [assetslibrary assetForURL:_imageURL
                                   resultBlock:^(ALAsset *asset){
                                       ALAssetRepresentation *rep = [asset defaultRepresentation];
                                       CGImageRef iref = [rep fullScreenImage];
                                       if (iref) {
                                           self.image = [UIImage imageWithCGImage:iref];
                                       }
                                       dispatch_async(dispatch_get_main_queue(), ^
                                                      {
                                                          self.imageDownloadState = KZImageDownloadStateFinished;
                                                          self.srcImageView.image = self.image;
                                                          _loadingInProgress = NO;
                                                      });
                                   }
                                  failureBlock:^(NSError *error) {
                                      self.image = nil;
                                      dispatch_async(dispatch_get_main_queue(), ^
                                                     {
                                                         self.imageDownloadState = KZImageDownloadStateFailed;
                                                         _loadingInProgress = NO;
                                                     });
                                  }];
                }
            });
        }
        else if ([_imageURL isFileReferenceURL])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool
                {
                    self.image = [UIImage imageWithContentsOfFile:_imageURL.path];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!self.image) {
                            NSLog(@"Error loading photo from path: %@", _imageURL.path);
                            self.imageDownloadState = KZImageDownloadStateFailed;
                        } else {
                            self.imageDownloadState = KZImageDownloadStateFinished;
                            self.srcImageView.image = self.image;
                        }
                        _loadingInProgress = NO;
                    });
                }
            });
            
        }
        else
        {
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            
            _webImageOperation = [manager downloadImageWithURL:_imageURL
                                                       options:0
                                                      progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                          if (expectedSize > 0)
                                                          {
                                                              float progress = receivedSize / (float)expectedSize;
                                                              self.downloadProgress = [NSNumber numberWithFloat:progress];
                                                          }
                                                      } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                                          self.image = image;
                                                          //self.srcImageView.image = image;
                                                          self.imageDownloadState = KZImageDownloadStateFinished;
                                                          if (error) {
                                                              NSLog(@"SDWebImage failed to download image: %@", error);
                                                              self.imageDownloadState = KZImageDownloadStateFailed;
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
        self.imageDownloadState = KZImageDownloadStateFailed;
    }
}
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"imageDownloadState"] || [theKey isEqualToString:@"downloadProgress"])
    {
        automatic = YES;
    }
    return automatic;
}
@end
