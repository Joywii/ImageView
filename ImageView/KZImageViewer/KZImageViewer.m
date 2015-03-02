//
//  KZImageViewer.m
//  KuaiZhanNativeApp
//
//  Created by joywii on 14/10/22.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import "KZImageViewer.h"
#import "KZImageScrollView.h"
#import "KZImage.h"
#import "SDImageCache.h"

#define kPadding  10

@interface KZImageViewer ()<UIScrollViewDelegate,KZImageScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, strong) NSMutableArray *scrollImageViewArray;
@property (nonatomic, strong) UIImageView *selectImageView;

@end

@implementation KZImageViewer

- (id)init
{
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self)
    {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self)
    {
        [self setup];
    }
    return self;
}
- (void)setup
{
    self.backgroundColor = [UIColor blackColor];
    self.scrollImageViewArray = [NSMutableArray array];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:[self frameForPagingScrollView]];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.delegate = self;
    [self addSubview:_scrollView];
}
- (void)showImages:(NSArray *)imageArray atIndex:(NSInteger)index
{
    self.alpha = 0.0;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    const NSInteger currentPage = index;
    self.selectIndex = currentPage;
    KZImage *kzSelectImage = [imageArray objectAtIndex:currentPage];
    UIImage *selectImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kzSelectImage.imageURL.absoluteString];
    if (!selectImage) {
        selectImage = kzSelectImage.thumbnailImage;
    }
    UIImageView *selectImageView = kzSelectImage.srcImageView;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * [imageArray count], self.scrollView.bounds.size.height);
    self.scrollView.contentOffset = CGPointMake(currentPage * self.scrollView.bounds.size.width, 0);
    
    //用来显示动画的ImageView
    CGRect selectImageViewFrame = [window convertRect:selectImageView.frame fromView:selectImageView.superview];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:selectImageViewFrame];
    imageView.contentMode = selectImageView.contentMode;
    imageView.clipsToBounds = YES;
    imageView.image = selectImage;
    imageView.backgroundColor = [UIColor clearColor];
    imageView.userInteractionEnabled = YES;
    
    [window addSubview:imageView];
    
    const CGFloat fullWidth = window.frame.size.width;
    const CGFloat fullHeight = window.frame.size.height;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         self.alpha = 1.0;
                         
                         imageView.transform = CGAffineTransformIdentity;
                         CGSize size = (imageView.image) ? imageView.image.size : imageView.frame.size;
                         CGFloat ratio = MIN(fullWidth / size.width, fullHeight / size.height);
                         CGFloat W = ratio > 1 ? size.width : ratio * size.width;
                         CGFloat H = ratio > 1 ? size.height : ratio * size.height;
                         imageView.frame = CGRectMake((fullWidth - W) / 2, (fullHeight - H) / 2, W, H);
                         
                     } completion:^(BOOL finished) {
                         
                         for (int i = 0; i < [imageArray count]; i++)
                         {
                             KZImage *kzImage  = [imageArray objectAtIndex:i];
                             
                             KZImageScrollView *zoomImageView = [[KZImageScrollView alloc] initWithFrame:[self frameForPageAtIndex:i]];
                             
                             zoomImageView.kzImage = kzImage;
                             zoomImageView.imageDelegate = self;
                             zoomImageView.userInteractionEnabled = YES;
                             
                             //如果当前KZImage没有图片 开始下载
                             if (i == currentPage)
                             {
                                 if (!kzImage.image)
                                 {
                                     [zoomImageView startLoadImage];
                                 }
                             }
                             [self.scrollView addSubview:zoomImageView];
                             [self.scrollImageViewArray addObject:zoomImageView];
                         }
                         [self preLoadImage:currentPage];
                         [imageView removeFromSuperview];//删除用来动画的ImageView
                     }];

}
- (void)showImages:(NSArray *)imageArray selectImageView:(UIImageView *)selectImageView atIndex:(NSInteger)index
{
    self.alpha = 0.0;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    const NSInteger currentPage = index;
    self.selectIndex = currentPage;
    self.selectImageView = selectImageView;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width * [imageArray count], self.scrollView.bounds.size.height);
    self.scrollView.contentOffset = CGPointMake(currentPage * self.scrollView.bounds.size.width, 0);
    
    //用来显示动画的ImageView
    CGRect selectImageViewFrame = [window convertRect:selectImageView.frame fromView:selectImageView.superview];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:selectImageViewFrame];
    imageView.contentMode = selectImageView.contentMode;
    imageView.clipsToBounds = YES;
    imageView.image = selectImageView.image;
    imageView.backgroundColor = [UIColor clearColor];
    imageView.userInteractionEnabled = YES;
    
    [window addSubview:imageView];
    
    const CGFloat fullWidth = window.frame.size.width;
    const CGFloat fullHeight = window.frame.size.height;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         self.alpha = 1.0;
                         
                         imageView.transform = CGAffineTransformIdentity;
                         CGSize size = (imageView.image) ? imageView.image.size : imageView.frame.size;
                         CGFloat ratio = MIN(fullWidth / size.width, fullHeight / size.height);
                         CGFloat W = ratio > 1 ? size.width : ratio * size.width;
                         CGFloat H = ratio > 1 ? size.height : ratio * size.height;
                         imageView.frame = CGRectMake((fullWidth - W) / 2, (fullHeight - H) / 2, W, H);
                         
                     } completion:^(BOOL finished) {
                         
                         for (int i = 0; i < [imageArray count]; i++)
                         {
                             KZImage *kzImage  = [imageArray objectAtIndex:i];
                             
                             KZImageScrollView *zoomImageView = [[KZImageScrollView alloc] initWithFrame:[self frameForPageAtIndex:i]];
                             
                             zoomImageView.kzImage = kzImage;
                             zoomImageView.imageDelegate = self;
                             zoomImageView.userInteractionEnabled = YES;
                             
                             //如果当前KZImage没有图片 开始下载
                             if (i == currentPage)
                             {
                                 if (!kzImage.image)
                                 {
                                     [zoomImageView startLoadImage];
                                 }
                             }
                             [self.scrollView addSubview:zoomImageView];
                             [self.scrollImageViewArray addObject:zoomImageView];
                         }
                         [imageView removeFromSuperview];//删除用来动画的ImageView
                     }];
}
- (void)tappedScrollView:(UITapGestureRecognizer *)sender
{
    [self hide];
}
- (void)hide
{
    for (KZImageScrollView *imageView in self.scrollImageViewArray)
    {
        [imageView cancelLoadImage];
        [imageView removeFromSuperview];
    }
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    const CGFloat fullWidth = window.frame.size.width;
    const CGFloat fullHeight = window.frame.size.height;

    //获取当前 Image
    NSInteger index = [self pageIndex];
    KZImageScrollView *zoomImageView = [self.scrollImageViewArray objectAtIndex:index];
    
    CGSize size = (zoomImageView.kzImage.image) ? zoomImageView.kzImage.image.size : zoomImageView.frame.size;
    CGFloat ratio = MIN(fullWidth / size.width, fullHeight / size.height);
    CGFloat W = ratio > 1 ? size.width : ratio * size.width;
    CGFloat H = ratio > 1 ? size.height : ratio * size.height;
    CGRect frame = CGRectMake((fullWidth - W) / 2, (fullHeight - H) / 2, W, H);
    
    //用于动画的ImageView
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.image = zoomImageView.kzImage.image;
    
    imageView.backgroundColor = [UIColor clearColor];
    imageView.userInteractionEnabled = YES;
    [window addSubview:imageView];
    
    //CGRect selectImageViewFrame = [window convertRect:self.selectImageView.frame fromView:self.selectImageView.superview];
    CGRect selectImageViewFrame = [window convertRect:zoomImageView.kzImage.srcImageView.frame fromView:zoomImageView.kzImage.srcImageView.superview];

    [UIView animateWithDuration:0.3
                     animations:^{
                         
                         self.alpha = 0.0;
                         imageView.frame = selectImageViewFrame;
                         
//                         if (self.selectIndex == [self pageIndex])
//                         {
//                             imageView.frame = selectImageViewFrame;
//                         }
//                         else
//                         {
//                             imageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
//                             imageView.alpha = 0.0;
//                         }
                     } completion:^(BOOL finished) {
                         for (KZImageScrollView *imageView in self.scrollImageViewArray)
                         {
                             [[SDImageCache sharedImageCache] removeImageForKey:imageView.kzImage.imageURL.absoluteString fromDisk:NO];
                         }
                         [imageView removeFromSuperview];
                         [self removeFromSuperview];
                     }];
}
- (NSInteger)pageIndex
{
    return (self.scrollView.contentOffset.x / self.scrollView.frame.size.width);
}
//////////////////////////////////////////////////////////// Frame 相关 ////////////////////////////////////////////////////////////

- (CGRect)frameForPagingScrollView
{
    CGRect frame = self.bounds;
    frame.origin.x -= kPadding;
    frame.size.width += (2 * kPadding);
    return CGRectIntegral(frame);
}
- (CGRect)frameForPageAtIndex:(NSUInteger)index
{
    CGRect bounds = self.scrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * kPadding);
    pageFrame.origin.x = (bounds.size.width * index) + kPadding;
    return CGRectIntegral(pageFrame);
}
//////////////////////////////////////////////////////////// KZImageScrollViewDelegate ////////////////////////////////////////////////////////////

#pragma mark - KZImageScrollViewDelegate
- (void)imageScrollViewSingleTap:(KZImageScrollView *)imageScrollView
{
    [self hide];
}
- (void)preLoadImage:(NSInteger)currentIndex
{
    NSInteger preIndex = currentIndex - 1;
    if (preIndex >= 0) {
        KZImageScrollView *preZoomImageView = [self.scrollImageViewArray objectAtIndex:preIndex];
        [preZoomImageView startLoadImage];
    }
    NSInteger nextIndex = currentIndex + 1;
    if (nextIndex <  [self.scrollImageViewArray count]) {
        KZImageScrollView *nextZoomImageView = [self.scrollImageViewArray objectAtIndex:nextIndex];
        [nextZoomImageView startLoadImage];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Update nav when page changes
    NSInteger index = [self pageIndex];
    KZImageScrollView *zoomImageView = [self.scrollImageViewArray objectAtIndex:index];
    [zoomImageView startLoadImage];
    
    [self preLoadImage:index];
}
@end
