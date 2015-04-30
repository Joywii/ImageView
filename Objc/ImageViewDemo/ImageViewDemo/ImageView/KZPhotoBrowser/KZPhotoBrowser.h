//
//  KZPhotoBrowser.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-10.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KZPhoto.h"


@class KZPhotoBrowser;

@protocol KZPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(KZPhotoBrowser *)photoBrowser;
- (KZPhoto *)photoBrowser:(KZPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(KZPhotoBrowser *)photoBrowser deletePhotoAtIndex:(NSUInteger)index;

@optional
- (KZPhoto *)photoBrowser:(KZPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;
- (NSString *)photoBrowser:(KZPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index;

@end

@interface KZPhotoBrowser : UIViewController

@property (nonatomic, weak) id<KZPhotoBrowserDelegate> delegate;
@property (nonatomic, assign) NSUInteger delayToHideElements;
@property (nonatomic, strong) UIColor *pbBarTintColor;


- (id)initWithDelegate:(id <KZPhotoBrowserDelegate>) delegate;

- (void)reloadData;

- (void)setCurrentPhotoIndex:(NSUInteger)index;

//Private
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

@end
