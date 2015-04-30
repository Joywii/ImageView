//
//  KZImageScrollView.m
//  KuaiZhanNativeApp
//
//  Created by joywii on 14/10/22.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import "KZImageScrollView.h"
#import "DACircularProgressView.h"

@interface KZImageScrollView ()

@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, strong) DACircularProgressView *progressView;
@end

@implementation KZImageScrollView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        self.clipsToBounds = YES;
        // Image view
        _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.contentMode = UIViewContentModeCenter;
        _photoImageView.backgroundColor = [UIColor blackColor];
        [self addSubview:_photoImageView];
        
        // Loading indicator
        _progressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - 20, self.bounds.size.height / 2 - 20, 40.0f, 40.0f)];
        _progressView.userInteractionEnabled = NO;
        _progressView.thicknessRatio = 0.1;
        _progressView.roundedCorners = NO;
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_progressView];
        
        // 属性
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // 监听点击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.delaysTouchesBegan = YES;
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        
        [singleTap requireGestureRecognizerToFail:doubleTap];
    }
    return self;
}
- (void)setKzImage:(KZImage *)kzImage
{
    if (_kzImage != kzImage)
    {
        if (_kzImage && kzImage == nil)
        {
            if ([_kzImage respondsToSelector:@selector(cancelAnyLoading)])
            {
                //不取消，以防止重新下载
                //[_photo cancelAnyLoading];
            }
        }
        [_kzImage removeObserver:self forKeyPath:@"imageDownloadState"];
        [_kzImage removeObserver:self forKeyPath:@"downloadProgress"];
        _kzImage = kzImage;
        [_kzImage addObserver:self
                 forKeyPath:@"imageDownloadState"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:nil];
        [_kzImage addObserver:self
                 forKeyPath:@"downloadProgress"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:nil];
        if (_kzImage)
        {
//            if (_kzImage.image)
//            {
//                [self displayImage];
//            }
//            else
//            {
//                //显示小图或者什么都不现实
//                //[self showLoadingIndicator];
//                //[_photo loadImage];
//            }
            [self displayImage];
        }
    }
}
- (void)dealloc
{
    [_kzImage removeObserver:self forKeyPath:@"imageDownloadState" context:nil];
    [_kzImage removeObserver:self forKeyPath:@"downloadProgress" context:nil];
}
#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"imageDownloadState"])
    {
        //更新状态
        KZImageDownloadState imageDownloadState = (KZImageDownloadState)[(NSNumber *)[change objectForKey:NSKeyValueChangeNewKey] intValue];
        if (imageDownloadState == KZImageDownloadStateFinished)
        {
            [self displayImage];
        }
    }
    if ([keyPath isEqualToString:@"downloadProgress"])
    {
        //更新进度
        NSNumber *progress = (NSNumber *)[self.kzImage valueForKeyPath:@"downloadProgress"];
        //NSLog(@"Download Image %f",[progress floatValue]);
        _progressView.progress = MAX(MIN(1, [progress floatValue]), 0);
    }
}
- (void)startLoadImage
{
    if (!self.kzImage.image)
    {
        [self showLoadingIndicator];
        [self.kzImage loadImage];
    }
}
- (void)cancelLoadImage
{
    [self.kzImage cancelAnyLoading];
}
- (void)hideLoadingIndicator
{
    _progressView.hidden = YES;
}
- (void)showLoadingIndicator
{
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    _progressView.progress = 0;
    _progressView.hidden = NO;
}
- (void)displayImage
{
    if (_kzImage) //&& _photoImageView.image == nil)
    {
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        // Get image from browser as it handles ordering of fetching
        UIImage *img;
        if (self.kzImage.image) {
            img = self.kzImage.image;
        } else {
            img = self.kzImage.thumbnailImage;
        }
        if (img)
        {
            [self hideLoadingIndicator];
            // Set image
            _photoImageView.image = img;
            _photoImageView.hidden = NO;
            
            // Setup photo frame
            CGRect photoImageViewFrame;
            photoImageViewFrame.origin = CGPointZero;
            photoImageViewFrame.size = img.size;
            _photoImageView.frame = photoImageViewFrame;
            self.contentSize = photoImageViewFrame.size;
            
            // Set zoom to minimum zoom
            [self setMaxMinZoomScalesForCurrentBounds];
        }
        [self setNeedsLayout];
    }
}
/*
 * 设置图片的放大和缩小参数
 */
- (void)setMaxMinZoomScalesForCurrentBounds
{
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (_photoImageView.image == nil) return;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 2;
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = minScale;
    
    // Layout
    [self setNeedsLayout];
}
- (void)layoutSubviews
{
    
    // Update tap view frame
    if (!_progressView.hidden)
    {
        _progressView.frame = CGRectMake(floorf((self.bounds.size.width - _progressView.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - _progressView.frame.size.height) / 2),
                                         _progressView.frame.size.width,
                                         _progressView.frame.size.height);
    }
    
    // Super
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
        _photoImageView.frame = frameToCenter;
    
}
#pragma mark - 手势处理
- (void)handleSingleTap:(UITapGestureRecognizer *)tap
{
    if (self.zoomScale != self.minimumZoomScale)
    {
        [self setZoomScale:self.minimumZoomScale animated:NO];
    }
    if (self.imageDelegate && [self.imageDelegate respondsToSelector:@selector(imageScrollViewSingleTap:)])
    {
        [self.imageDelegate imageScrollViewSingleTap:self];
    }
}
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap
{
    CGPoint touchPoint = [tap locationInView:self];
    if (self.zoomScale != self.minimumZoomScale)
    {
        [self setZoomScale:self.minimumZoomScale animated:YES];
    }
    else
    {
        //[self zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}
#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.scrollEnabled = YES; // reset
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}


@end
