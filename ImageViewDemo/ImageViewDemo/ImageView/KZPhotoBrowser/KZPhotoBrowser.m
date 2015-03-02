//
//  KZPhotoBrowser.m
//  KuaiZhanNativeApp
//
//  Created by joywii on 14-10-10.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import "KZPhotoBrowser.h"
#import "KZZoomingScrollView.h"

#define kPadding                10

@interface KZPhotoBrowser ()<UIScrollViewDelegate>
{
    //Data
    NSUInteger _photoCount;
    NSMutableArray *_photos;
    
    //Page Ctrl
    NSUInteger _currentPageIndex;
    NSUInteger _previousPageIndex;
    NSMutableSet *_visiblePages, *_recycledPages;
    
    //Page View
    UIScrollView *_pagingScrollView;
    CGRect _previousLayoutBounds;
    
    NSTimer *_controlVisibilityTimer;
    
    BOOL _isVCBasedStatusBarAppearance;
    BOOL _statusBarShouldBeHidden;
    BOOL _leaveStatusBarAlone;
    BOOL _performingLayout;
    BOOL _rotating;
    BOOL _viewIsActive;
    
    //Nav Appearance
    BOOL _didSavePreviousStateOfNavBar;
    BOOL _previousNavBarHidden;
    BOOL _previousNavBarTranslucent;
    UIBarStyle _previousNavBarStyle;
    UIStatusBarStyle _previousStatusBarStyle;
    UIColor *_previousNavBarTintColor;
    UIColor *_previousNavBarBarTintColor;
    UIBarButtonItem *_previousViewControllerBackButton;
    UIImage *_previousNavigationBarBackgroundImageDefault;
    UIImage *_previousNavigationBarBackgroundImageLandscapePhone;
}
@end

@implementation KZPhotoBrowser

- (id)init
{
    if ((self = [super init])) {
        [self setup];
    }
    return self;
}

- (id)initWithDelegate:(id <KZPhotoBrowserDelegate>)delegate
{
    if ((self = [self init])) {
        _delegate = delegate;
    }
    return self;
}
- (void)setup
{
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (isVCBasedStatusBarAppearanceNum)
    {
        _isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
    }
    else
    {
        _isVCBasedStatusBarAppearance = YES;
    }
    _photoCount = NSNotFound;
    _currentPageIndex = 0;
    _previousPageIndex = NSUIntegerMax;
    _performingLayout = NO;
    _rotating = NO;

    _delayToHideElements = 5;
    _visiblePages  = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos        = [[NSMutableArray alloc] init];
    
    self.hidesBottomBarWhenPushed = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _pbBarTintColor = [UIColor blackColor];
}

- (void)dealloc {
    _pagingScrollView.delegate = nil;
    [self releaseAllUnderlyingPhotos:NO];
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent
{
    NSArray *copy = [_photos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self photoAtIndex:self.currentIndex]) {
                continue; // skip current
            }
            [p unloadImage];
        }
    }
}
- (void)didReceiveMemoryWarning
{
    [self releaseAllUnderlyingPhotos:YES];
    [_recycledPages removeAllObjects];
    [super didReceiveMemoryWarning];
}
- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    
    //Right Button
    UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"删除" style:UIBarButtonItemStylePlain target:self action:@selector(deleteCurrentImage)];
    self.navigationItem.rightBarButtonItem = deleteButtonItem;
    
    // Setup paging scrolling view
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    _pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    _pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _pagingScrollView.pagingEnabled = YES;
    _pagingScrollView.delegate = self;
    _pagingScrollView.showsHorizontalScrollIndicator = NO;
    _pagingScrollView.showsVerticalScrollIndicator = NO;
    _pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    [self.view addSubview:_pagingScrollView];
    
    [self reloadData];
    [super viewDidLoad];
}
// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    _currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
    [super viewDidUnload];
}
- (void)viewWillAppear:(BOOL)animated
{
    // Super
    [super viewWillAppear:animated];
    
    // Status bar
    if ([UIViewController instancesRespondToSelector:@selector(prefersStatusBarHidden)]) {
        _leaveStatusBarAlone = [self presentingViewControllerPrefersStatusBarHidden];
    } else {
        _leaveStatusBarAlone = [UIApplication sharedApplication].statusBarHidden;
    }
    if (CGRectEqualToRect([[UIApplication sharedApplication] statusBarFrame], CGRectZero)) {
        _leaveStatusBarAlone = YES;
    }
    if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
    }
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    [self setNavBarAppearance:animated];
    // Update UI
    [self hideControlsAfterDelay];
}
- (void)viewWillDisappear:(BOOL)animated
{
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self && ![self.navigationController.viewControllers containsObject:self])
    {
        // State
        _viewIsActive = NO;
        // Bar state / appearance
        [self restorePreviousNavBarAppearance:animated];
    }
    
    // Controls
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    [self setControlsHidden:NO animated:NO permanent:YES];
    
    // Status bar
    if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }
    // Super
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}
- (NSUInteger)numberOfPhotos
{
    if (_photoCount == NSNotFound)
    {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)])
        {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}
- (KZPhoto *)photoAtIndex:(NSUInteger)index
{
    KZPhoto *photo = nil;
    if (index < _photos.count)
    {
        if ([_photos objectAtIndex:index] == [NSNull null])
        {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)])
            {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            }
            if (photo)
            {
                [_photos replaceObjectAtIndex:index withObject:photo];
            }
        }
        else
        {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}
- (NSUInteger)currentIndex
{
    return _currentPageIndex;
}
- (void)deleteCurrentImage
{
    if (_photoCount > 0)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowser:deletePhotoAtIndex:)])
        {
            [self.delegate photoBrowser:self deletePhotoAtIndex:_currentPageIndex];
            [self reloadData];
            if (_photoCount <= 0)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
}
- (void)reloadData
{
    // Reset
    _photoCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [_photos removeAllObjects];
    for (int i = 0; i < numberOfPhotos; i++)
    {
        [_photos addObject:[NSNull null]];
    }
    // Update current page index
    if (numberOfPhotos > 0)
    {
        _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfPhotos - 1));
    }
    else
    {
        _currentPageIndex = 0;
    }
    
    // Update layout
    if ([self isViewLoaded])
    {
        while (_pagingScrollView.subviews.count)
        {
            [[_pagingScrollView.subviews lastObject] removeFromSuperview];
        }
        [self performLayout];
        [self.view setNeedsLayout];
    }
}
- (void)performLayout {
    
    // Setup
    _performingLayout = YES;
    
    // Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];

    // Update nav
    [self updateNavigation];
    
    // Content offset
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self handlePages];
    _performingLayout = NO;
}
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}
- (void)layoutVisiblePages {
    
    // Flag
    _performingLayout = YES;
    
    // Remember index
    NSUInteger indexPriorToLayout = _currentPageIndex;
    
    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // Adjust frames and configuration of each visible page
    for (KZZoomingScrollView *page in _visiblePages)
    {
        NSUInteger index = page.index;
        page.frame = [self frameForPageAtIndex:index];
        
        // Adjust scales if bounds has changed since last time
        if (!CGRectEqualToRect(_previousLayoutBounds, self.view.bounds)) {
            // Update zooms for new bounds
            [page setMaxMinZoomScalesForCurrentBounds];
            _previousLayoutBounds = self.view.bounds;
        }
        
    }
    
    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
    [self didStartViewingPageAtIndex:_currentPageIndex]; // initial
    
    // Reset
    _currentPageIndex = indexPriorToLayout;
    _performingLayout = NO;
}

////////////////////////////////////////////////////////////////////////////////////   page control  ////////////////////////////////////////////////////////////////////////////////////

- (void)handlePages
{
    //计算的最大和最小要显示的图片下标是多少？
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger iFirstIndex = (NSInteger)floorf((CGRectGetMinX(visibleBounds)+kPadding*2) / CGRectGetWidth(visibleBounds));
    NSInteger iLastIndex  = (NSInteger)floorf((CGRectGetMaxX(visibleBounds)-kPadding*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;

    // Recycle no longer needed pages
    NSInteger pageIndex;
    for (KZZoomingScrollView *page in _visiblePages)
    {
        pageIndex = page.index;
        if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
            [_recycledPages addObject:page];
            [page prepareForReuse];
            [page removeFromSuperview];
        }
    }
    [_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    
    // Add missing pages
    for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            // Add new page
            KZZoomingScrollView *page = [self dequeueRecycledPage];
            if (!page) {
                page = [[KZZoomingScrollView alloc] initWithPhotoBrowser:self];
            }
            [_visiblePages addObject:page];
            [self configurePage:page forIndex:index];
            
            [_pagingScrollView addSubview:page];
        }
    }
}
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    for (KZZoomingScrollView *page in _visiblePages)
        if (page.index == index) return YES;
    return NO;
}
- (KZZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index
{
    KZZoomingScrollView *thePage = nil;
    for (KZZoomingScrollView *page in _visiblePages) {
        if (page.index == index) {
            thePage = page; break;
        }
    }
    return thePage;
}

- (KZZoomingScrollView *)pageDisplayingPhoto:(KZPhoto *)photo
{
    KZZoomingScrollView *thePage = nil;
    for (KZZoomingScrollView *page in _visiblePages) {
        if (page.photo == photo) {
            thePage = page; break;
        }
    }
    return thePage;
}

- (void)configurePage:(KZZoomingScrollView *)page forIndex:(NSUInteger)index
{
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.photo = [self photoAtIndex:index];
}
- (KZZoomingScrollView *)dequeueRecycledPage
{
    KZZoomingScrollView *page = [_recycledPages anyObject];
    if (page)
    {
        [_recycledPages removeObject:page];
    }
    return page;
}

- (void)setCurrentPhotoIndex:(NSUInteger)index
{
    // Validate
    NSUInteger photoCount = [self numberOfPhotos];
    if (photoCount == 0)
    {
        index = 0;
    }
    else
    {
        if (index >= photoCount)
        {
            index = [self numberOfPhotos]-1;
        }
    }
    _currentPageIndex = index;
    if ([self isViewLoaded])
    {
        [self jumpToPageAtIndex:index animated:NO];
        if (!_viewIsActive)
        {
            [self handlePages]; // Force tiling if view is not visible
        }
    }
}
- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    // Change page
    if (index < [self numberOfPhotos])
    {
        CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - kPadding, 0) animated:animated];
        [self updateNavigation];
    }
    // Update timer to give more time
    [self hideControlsAfterDelay];
    
}
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
    // Force visible
    if (![self numberOfPhotos])
        hidden = NO;
    
    // Cancel any timers
    [self cancelControlHiding];
    
    // Animations & positions
    CGFloat animationDuration = (animated ? 0.35 : 0);
    
    // Status bar
    if (!_leaveStatusBarAlone)
    {
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        {
            // iOS 7
            // Hide status bar
            if (!_isVCBasedStatusBarAppearance)
            {
                // Non-view controller based
                [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
                
            } else {
                // View controller based so animate away
                _statusBarShouldBeHidden = hidden;
                [UIView animateWithDuration:animationDuration animations:^(void) {
                    [self setNeedsStatusBarAppearanceUpdate];
                } completion:^(BOOL finished) {}];
            }
        }
    }
    [UIView animateWithDuration:animationDuration animations:^(void)
    {
        CGFloat alpha = hidden ? 0 : 1;
        // Nav bar slides up on it's own on iOS 7
        [self.navigationController.navigationBar setAlpha:alpha];
    } completion:^(BOOL finished) {}];
    
    if (!permanent)
    {
        [self hideControlsAfterDelay];
    }
}
// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index
{
    if (![self numberOfPhotos]) {
        // Show controls
        [self setControlsHidden:NO animated:YES permanent:YES];
        return;
    }
    
    // Release images further away than +/-1
    NSUInteger i;
    if (index > 0) {
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
            }
        }
    }
    if (index < [self numberOfPhotos] - 1) {
        // Release anything > index + 1
        for (i = index + 2; i < _photos.count; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
            }
        }
    }
    
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    KZPhoto *currentPhoto = [self photoAtIndex:index];
    if ([currentPhoto image]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
    // Update nav
    [self updateNavigation];
}
- (void)loadAdjacentPhotosIfNecessary:(KZPhoto *)photo
{
    KZZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page)
    {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = page.index;
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                KZPhoto *photo = [self photoAtIndex:pageIndex-1];
                if (![photo image]) {
                    [photo loadImage];
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                KZPhoto *photo = [self photoAtIndex:pageIndex+1];
                if (![photo image]) {
                    [photo loadImage];
                }
            }
        }
    }
}
////////////////////////////////////////////////////////////////////////////////////   UIScrollView  ////////////////////////////////////////////////////////////////////////////////////

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Checks
    if (!_viewIsActive || _performingLayout || _rotating) return;
    
    // Tile pages
    [self handlePages];
    
    // Calculate current page
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage)
    {
        [self didStartViewingPageAtIndex:index];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Hide controls when dragging begins
    [self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Update nav when page changes
    [self updateNavigation];
}

////////////////////////////////////////////////////////////////////////////////////   NavgationBar  ////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Nav Bar Appearance

- (void)setNavBarAppearance:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    if ([navBar respondsToSelector:@selector(setBarTintColor:)]) {
        navBar.barTintColor = nil;
        navBar.shadowImage = nil;
    }
    navBar.barTintColor = self.pbBarTintColor;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];
    }
}

- (void)storePreviousNavBarAppearance
{
    _didSavePreviousStateOfNavBar = YES;
    if ([UINavigationBar instancesRespondToSelector:@selector(barTintColor)]) {
        _previousNavBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    }
    _previousNavBarTranslucent = self.navigationController.navigationBar.translucent;
    _previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarHidden = self.navigationController.navigationBarHidden;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        _previousNavigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        _previousNavigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompact];
    }
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated
{
    if (_didSavePreviousStateOfNavBar) {
        [self.navigationController setNavigationBarHidden:_previousNavBarHidden animated:animated];
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.tintColor = _previousNavBarTintColor;
        navBar.translucent = _previousNavBarTranslucent;
        if ([UINavigationBar instancesRespondToSelector:@selector(barTintColor)]) {
            navBar.barTintColor = _previousNavBarBarTintColor;
        }
        navBar.barStyle = _previousNavBarStyle;
        if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
            [navBar setBackgroundImage:_previousNavigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
            [navBar setBackgroundImage:_previousNavigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsCompact];
        }
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            _previousViewControllerBackButton = nil;
        }
    }
}
#pragma mark - Navigation

- (void)updateNavigation
{
    // Title
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    if (numberOfPhotos > 1)
    {
        if ([_delegate respondsToSelector:@selector(photoBrowser:titleForPhotoAtIndex:)])
        {
            self.title = [_delegate photoBrowser:self titleForPhotoAtIndex:_currentPageIndex];
        }
        else
        {
            self.title = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(_currentPageIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long)numberOfPhotos];
        }
    }
    else
    {
        self.title = nil;
    }
}
- (void)cancelControlHiding
{
    if (_controlVisibilityTimer)
    {
        [_controlVisibilityTimer invalidate];
        _controlVisibilityTimer = nil;
    }
}
- (void)hideControlsAfterDelay
{
    if (![self areControlsHidden])
    {
        [self cancelControlHiding];
        _controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:self.delayToHideElements target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    }
}
- (BOOL)areControlsHidden
{
    return [[UIApplication sharedApplication] isStatusBarHidden];
}
- (void)hideControls
{
    [self setControlsHidden:YES animated:YES permanent:NO];
}
- (void)toggleControls
{
    [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO];
}
- (BOOL)prefersStatusBarHidden
{
    if (!_leaveStatusBarAlone){
        return _statusBarShouldBeHidden;
    } else {
        return [self presentingViewControllerPrefersStatusBarHidden];
    }
}
- (BOOL)presentingViewControllerPrefersStatusBarHidden
{
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        if ([presenting isKindOfClass:[UINavigationController class]]) {
            presenting = [(UINavigationController *)presenting topViewController];
        }
    } else {
        // We're in a navigation controller so get previous one!
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            presenting = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        }
    }
    if (presenting) {
        return [presenting prefersStatusBarHidden];
    } else {
        return NO;
    }
}
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationSlide;
}
////////////////////////////////////////////////////////////////////////////////////Frame Calculations////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Frame Calculations
- (CGRect)frameForPagingScrollView
{
    CGRect frame = self.view.bounds;
    frame.origin.x -= kPadding;
    frame.size.width += (2 * kPadding);
    return CGRectIntegral(frame);
}
- (CGRect)frameForPageAtIndex:(NSUInteger)index
{
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * kPadding);
    pageFrame.origin.x = (bounds.size.width * index) + kPadding;
    return CGRectIntegral(pageFrame);
}
- (CGSize)contentSizeForPagingScrollView
{
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index
{
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);
}
@end






