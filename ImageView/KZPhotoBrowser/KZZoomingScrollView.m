//
//  KZZoomingScrollView.m
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-10.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import "KZZoomingScrollView.h"
#import "KZTapDetectingImageView.h"
#import "KZTapDetectingView.h"
#import "DACircularProgressView.h"


@interface KZZoomingScrollView ()<KZTapDetectingImageViewDelegate,KZTapDetectingViewDelegate>
{
    
}
@property (nonatomic, weak) KZPhotoBrowser *photoBrowser;
@property (nonatomic, strong) KZTapDetectingView *tapView;
@property (nonatomic, strong) KZTapDetectingImageView *photoImageView;
@property (nonatomic, strong) DACircularProgressView *progressView;

@end
@implementation KZZoomingScrollView

- (id)initWithPhotoBrowser:(KZPhotoBrowser *)browser
{
    if ((self = [super init]))
    {
        // Setup
        _index = NSUIntegerMax;
        _photoBrowser = browser;
        
        // Tap view for background
        _tapView = [[KZTapDetectingView alloc] initWithFrame:self.bounds];
        _tapView.tapDelegate = self;
        _tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tapView.backgroundColor = [UIColor blackColor];
        [self addSubview:_tapView];
        
        // Image view
        _photoImageView = [[KZTapDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.tapDelegate = self;
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
        
        // Setup
        self.backgroundColor = [UIColor blackColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollsToTop = NO;
    }
    return self;
}
- (void)setPhoto:(KZPhoto *)photo
{
    if (_photo != photo)
    {
        if (_photo && photo == nil)
        {
            if ([_photo respondsToSelector:@selector(cancelAnyLoading)])
            {
                //不取消，以防止重新下载
                //[_photo cancelAnyLoading];
            }
        }
        [_photo removeObserver:self forKeyPath:@"photoDownloadState"];
        [_photo removeObserver:self forKeyPath:@"downloadProgress"];
        _photo = photo;
        [_photo addObserver:self
                 forKeyPath:@"photoDownloadState"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:nil];
        [_photo addObserver:self
                 forKeyPath:@"downloadProgress"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:nil];
        if (_photo)
        {
            if (_photo.image)
            {
                [self displayImage];
            }
            else
            {
                [self showLoadingIndicator];
                [_photo loadImage];
            }
        }
    }
}
- (void)dealloc
{
    [_photo removeObserver:self forKeyPath:@"photoDownloadState" context:nil];
    [_photo removeObserver:self forKeyPath:@"downloadProgress" context:nil];
}
#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"photoDownloadState"])
    {
        //更新状态
        KZPhotoDownloadState photoDownloadState = (KZPhotoDownloadState)[(NSNumber *)[change objectForKey:NSKeyValueChangeNewKey] intValue];
        if (photoDownloadState == KZPhotoDownloadStateFinished)
        {
            [self displayImage];
        }
    }
    if ([keyPath isEqualToString:@"downloadProgress"])
    {
        //更新进度
        NSNumber *progress = (NSNumber *)[self.photo valueForKeyPath:@"downloadProgress"];
        NSLog(@"Download Image %f",[progress floatValue]);
        _progressView.progress = MAX(MIN(1, [progress floatValue]), 0);
    }
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
- (void)prepareForReuse
{
    self.photo = nil;
    _photoImageView.image = nil;
    _index = NSUIntegerMax;
}

- (void)displayImage
{
    if (_photo && _photoImageView.image == nil)
    {
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        // Get image from browser as it handles ordering of fetching
        UIImage *img = self.photo.image;
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
- (void)layoutSubviews {
    
    // Update tap view frame
    _tapView.frame = self.bounds;
    
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
#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
    [_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}
#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint
{
    [_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
    
    // Zoom
    if (self.zoomScale != self.minimumZoomScale){
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
        
    } else {
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
    
    // Delay controls
    [_photoBrowser hideControlsAfterDelay];
    
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch
{
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch
{
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleSingleTap:CGPointMake(touchX, touchY)];
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    [self handleDoubleTap:CGPointMake(touchX, touchY)];
}

@end
