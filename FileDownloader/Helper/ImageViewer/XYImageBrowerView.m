//
//  XYImageBrowerView.m
//  image-viewer
//
//  Created by mofeini on 17/1/5.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "XYImageBrowerView.h"
#import "UIImageView+WebCache.h"

@interface XYImageBrowerView () <UIScrollViewDelegate, XYImageViewDelegate>
/// 图片数组，3个 XYImageView, 进行复用
@property (nonatomic, strong) NSMutableArray<XYImageView *> *pictureViews;
/// 准备待用的图片视图（缓存）
@property (nonatomic, strong) NSMutableArray<XYImageView *> *prepareUsePictureViews;
@property (nonatomic, assign) NSInteger picturesCount;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) XYImagePageLabel *pageTextLabel;

/// 消失的 tap 手势
@property (nonatomic, weak) UITapGestureRecognizer *dismissTapGes;


@end

@implementation XYImageBrowerView

@synthesize imagesSpacing = _imagesSpacing;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
    self.frame = [UIScreen mainScreen].bounds;
    self.backgroundColor = [UIColor clearColor];
    
    // 添加手势事件
    UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnSelf:)];
    [self addGestureRecognizer:longGes];
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureOnSelf:)];
    [self addGestureRecognizer:tapGes];
    self.dismissTapGes = tapGes;
}

- (void)showFromView:(UIView *)fromView picturesCount:(NSInteger)picturesCount currentPictureIndex:(NSInteger)currentPictureIndex {
    
    NSString *errorStr = [NSString stringWithFormat:@"Parameter is not correct, pictureCount is %zd, currentPictureIndex is %zd", picturesCount, currentPictureIndex];
    NSAssert(picturesCount > 0 && currentPictureIndex < picturesCount, errorStr);
    NSAssert(self.delegate != nil, @"Please set up delegate for pictureBrowser");
    
    // 记录值并设置位置
    _currentPage = currentPictureIndex;
    self.picturesCount = picturesCount;
    [self setPageText:currentPictureIndex];
    // 添加到 window 上
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    // 计算 scrollView 的 contentSize
    self.scrollView.contentSize = CGSizeMake(picturesCount * _scrollView.frame.size.width, _scrollView.frame.size.height);
    // 滚动到指定位置
    [self.scrollView setContentOffset:CGPointMake(currentPictureIndex * _scrollView.frame.size.width, 0) animated:false];
    // 设置第1个 view 的位置以及大小
    XYImageView *imageView = [self setPictureViewForIndex:currentPictureIndex];
    // 获取来源图片在屏幕上的位置
    CGRect rect = [fromView convertRect:fromView.bounds toView:nil];
    
    [imageView animationShowWithFromRect:rect duration:self.duration animationBlock:^{
        self.backgroundColor = [UIColor blackColor];
        self.pageTextLabel.alpha = 1;
    } completionBlock:^{
        // 设置左边与右边的 pictureView
        if (currentPictureIndex != 0 && picturesCount > 1) {
            // 设置左边
            [self setPictureViewForIndex:currentPictureIndex - 1];
        }
        
        if (currentPictureIndex < picturesCount - 1) {
            // 设置右边
            [self setPictureViewForIndex:currentPictureIndex + 1];
        }
    }];
}

- (void)dismiss {
    UIView *endView = [_delegate imageBrowerView:self viewForIndex:_currentPage];
    // 取到当前显示的 pictureView
    XYImageView *imageView = [[_pictureViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"index == %d", _currentPage]] firstObject];
    // 取消所有的下载
    for (XYImageView *imageView in _pictureViews) {
        [imageView.imageView sd_cancelCurrentImageLoad];
    }
    
    for (XYImageView *imageView in self.prepareUsePictureViews) {
        [imageView.imageView sd_cancelCurrentImageLoad];
    }
    
    CGRect endRect = [endView convertRect:endView.bounds toView:nil];
    if (!endView) {
        endRect = CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds)*0.5, CGRectGetHeight([UIScreen mainScreen].bounds)*0.5, 0, 0);
    }
    // 执行关闭动画
    [imageView animationDismissWithToRect:endRect duration:self.duration animationBlock:^{
        self.backgroundColor = [UIColor clearColor];
        //        self.pageTextLabel.alpha = 0;
    } completionBlock:^{
        [self removeFromSuperview];
        if (self.dismissCallBack) {
            self.dismissCallBack();
        }
    }];
}

#pragma mark - Events

- (void)tapGestureOnSelf:(UITapGestureRecognizer *)ges {
    [self dismiss];
}

- (void)longPressOnSelf:(UILongPressGestureRecognizer *)longPre {
    
    if (longPre.state == UIGestureRecognizerStateEnded) {
        if (self.longPressBlock) {
            self.longPressBlock(_currentPage);
        }
    }
}

#pragma mark - Private Methods


/**
 设置ImageView到指定位置
 
 @param index 索引
 
 @return 当前设置的控件
 */
- (XYImageView *)setPictureViewForIndex:(NSInteger)index {
    [self removeViewToReUse];
    XYImageView *view = [self createImageView];
    view.index = index;
    CGRect frame = view.frame;
    frame.size = self.frame.size;
    view.frame = frame;
    
    // 设置图片的大小<在下载完毕之后会根据下载的图片计算大小>
    CGSize defaultSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width);
    
    void(^setImageSizeBlock)(UIImage *) = ^(UIImage *image) {
        if (image != nil) {
            if (image != nil) {
                view.pictureSize = image.size;
            }else {
                view.pictureSize = defaultSize;
            }
        }
    };
    
    // 1. 判断是否实现图片大小的方法
    if ([_delegate respondsToSelector:@selector(imageBrowerView:imageSizeForIndex:)]) {
        view.pictureSize = [_delegate imageBrowerView:self imageSizeForIndex:index];
    }else if ([_delegate respondsToSelector:@selector(imageBrowerView:defaultImageForIndex:)]) {
        UIImage *image = [_delegate imageBrowerView:self defaultImageForIndex:index];
        // 2. 如果没有实现，判断是否有默认图片，获取默认图片大小
        setImageSizeBlock(image);
    } else if ([_delegate respondsToSelector:@selector(imageBrowerView:viewForIndex:)]) {
        UIView *v = [_delegate imageBrowerView:self viewForIndex:index];
        if ([v isKindOfClass:[UIImageView class]]) {
            UIImage *image = ((UIImageView *)v).image;
            setImageSizeBlock(image);
            // 并且设置占位图片
            view.placeholderImage = image;
        }
    }else {
        // 3. 如果都没有就设置为屏幕宽度，待下载完成之后再次计算
        view.pictureSize = defaultSize;
    }
    
    // 设置占位图
    if (_delegate && [_delegate respondsToSelector:@selector(imageBrowerViewWithImageNameArray:)]) {
        NSArray *imageNames = [_delegate imageBrowerViewWithImageNameArray:self];
        view.placeholderImage = [UIImage imageNamed:imageNames[index]];
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(imageBrowerView:defaultImageForIndex:)]) {
            view.placeholderImage = [_delegate imageBrowerView:self defaultImageForIndex:index];
        }
    }
    
    
    // 设置显示的图片
    if (_delegate && [_delegate respondsToSelector:@selector(imageBrowerViewWithOriginalImageUrlStrArray:)]) {
        NSArray *urlStrArr = [_delegate imageBrowerViewWithOriginalImageUrlStrArray:self];
        view.urlString = [urlStrArr objectAtIndex:index];
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(imageBrowerView:highQualityUrlStringForIndex:)]) {
            
            view.urlString = [_delegate imageBrowerView:self highQualityUrlStringForIndex:index];
        }
    }
    
    CGPoint center = view.center;
    center.x = index * _scrollView.frame.size.width + _scrollView.frame.size.width * 0.5;
    view.center = center;
    return view;
}


/**
 获取图片控件：如果缓存里面有，那就从缓存里面取，没有就创建
 
 @return 图片控件
 */
- (XYImageView *)createImageView {
    XYImageView *view;
    if (!self.prepareUsePictureViews.count) {
        view = [XYImageView new];
        // 手势事件冲突处理
        [self.dismissTapGes requireGestureRecognizerToFail:view.imageView.gestureRecognizers.firstObject];
        view.imageViewDelegate = self;
    }else {
        view = [self.prepareUsePictureViews firstObject];
        [self.prepareUsePictureViews removeObjectAtIndex:0];
    }
    [[self scrollView] addSubview:view];
    [[self pictureViews] addObject:view];
    return view;
}

- (CGFloat)duration {
    
    return _duration ?: 0.25;
}

/**
 移动到超出屏幕的视图到可重用数组里面去
 */
- (void)removeViewToReUse {
    
    NSMutableArray *tempArray = [NSMutableArray array];
    for (XYImageView *view in self.pictureViews) {
        // 判断某个view的页数与当前页数相差值为2的话，那么让这个view从视图上移除
        if (abs((int)view.index - (int)_currentPage) == 2){
            [tempArray addObject:view];
            [view removeFromSuperview];
            [self.prepareUsePictureViews addObject:view];
        }
    }
    [self.pictureViews removeObjectsInArray:tempArray];
}

/// 设置文字，并设置位置
- (void)setPageText:(NSUInteger)index {
    NSString *text = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(imageBrowerView:pageTextAtIndex:)]) {
        text = [self.delegate imageBrowerView:self pageTextAtIndex:index];
    }
    [self pageTextLabel].text = text ?: [NSString stringWithFormat:@"%zd / %zd", index + 1, self.picturesCount];
    [[self pageTextLabel] sizeToFit];
    [self pageTextLabel].center = self.pageTextLabel.center;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSUInteger page = (scrollView.contentOffset.x / scrollView.frame.size.width + 0.5);
    self.currentPage = page;
}

#pragma mark - XYImageViewDelegate

- (void)imageViewTouch:(XYImageView *)imageView {
    [self dismiss];
}

- (void)imageView:(XYImageView *)imageView scale:(CGFloat)scale {
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1 - scale];
    
}

- (void)imageViewDidScrollTopOrBottom:(XYImageView *)imageView {
    [UIView animateWithDuration:0.25 animations:^{
        self.pageTextLabel.alpha = 0.0;
    }];
}

- (void)imageViewDidEndDragging:(XYImageView *)imageView {
    [UIView animateWithDuration:0.25 animations:^{
        self.pageTextLabel.alpha = 1.0;
    }];
}

#pragma mark - set \ get

- (XYImagePageLabel *)pageTextLabel {
    if (_pageTextLabel == nil) {
        XYImagePageLabel *label = [[XYImagePageLabel alloc] init];
        label.alpha = 0.0;
        [self addSubview:label];
        label.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height - 20);
        _pageTextLabel = label;
    }
    [self bringSubviewToFront:_pageTextLabel];
    return _pageTextLabel;
}

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(-self.imagesSpacing * 0.5, 0, self.frame.size.width + self.imagesSpacing, self.frame.size.height)];
        scrollView.showsVerticalScrollIndicator = false;
        scrollView.showsHorizontalScrollIndicator = false;
        scrollView.pagingEnabled = true;
        scrollView.delegate = self;
        [self addSubview:scrollView];
        _scrollView = scrollView;
    }
    return _scrollView;
}


- (CGFloat)imagesSpacing {
    return _imagesSpacing ?: 20;
}

- (void)setImagesSpacing:(CGFloat)imagesSpacing {
    _imagesSpacing = imagesSpacing;
    self.scrollView.frame = CGRectMake(-_imagesSpacing * 0.5, 0, self.frame.size.width + _imagesSpacing, self.frame.size.height);
}

- (void)setCurrentPage:(NSInteger)currentPage {
    if (_currentPage == currentPage) {
        return;
    }
    NSUInteger oldValue = _currentPage;
    _currentPage = currentPage;
    [self removeViewToReUse];
    [self setPageText:currentPage];
    // 如果新值大于旧值
    if (currentPage > oldValue) {
        // 往右滑，设置右边的视图
        if (currentPage + 1 < _picturesCount) {
            [self setPictureViewForIndex:currentPage + 1];
        }
    }else {
        // 往左滑，设置左边的视图
        if (currentPage > 0) {
            [self setPictureViewForIndex:currentPage - 1];
        }
    }
    
}

- (NSMutableArray<XYImageView *> *)prepareUsePictureViews {
    if (!_prepareUsePictureViews) {
        _prepareUsePictureViews = [NSMutableArray arrayWithCapacity:0];
    }
    return _prepareUsePictureViews;
}

- (NSMutableArray<XYImageView *> *)pictureViews {
    if (!_pictureViews) {
        _pictureViews = [NSMutableArray arrayWithCapacity:0];
    }
    return _pictureViews;
}

- (void)dealloc {
    NSLog(@"%s", __func__);
}

@end


#pragma mark - XYImagePageLabel

@implementation XYImagePageLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont systemFontOfSize:16];
}



- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    [self sizeToFit];
}

@end


#pragma mark -  XYImageView

@interface XYImageView () <UIScrollViewDelegate>

@property (nonatomic, assign) CGSize showPictureSize;

@property (nonatomic, assign) BOOL doubleClicks;

@property (nonatomic, assign) CGPoint lastContentOffset;

@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, assign) CGFloat offsetY;

@property (nonatomic, weak) XYImageProgressView *progressView;

@property (nonatomic, assign, getter=isShowAnim) BOOL showAnim;
@end

@implementation XYImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.delegate = self;
    self.alwaysBounceVertical = true;
    self.backgroundColor = [UIColor clearColor];
    self.showsHorizontalScrollIndicator = false;
    self.showsVerticalScrollIndicator = false;
    self.maximumZoomScale = 2;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.clipsToBounds = true;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.frame = self.bounds;
    imageView.userInteractionEnabled = true;
    _imageView = imageView;
    [self addSubview:imageView];
    
    // 添加进度view
    XYImageProgressView *progressView = [[XYImageProgressView alloc] init];
    [self addSubview:progressView];
    self.progressView = progressView;
    
    // 添加监听事件
    UITapGestureRecognizer *doubleTapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleClick:)];
    doubleTapGes.numberOfTapsRequired = 2;
    [imageView addGestureRecognizer:doubleTapGes];
}

#pragma mark - 外部方法

- (void)animationShowWithFromRect:(CGRect)rect duration:(CGFloat)duration animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completionBlock {
    _imageView.frame = rect;
    self.showAnim = true;
    [self.progressView setHidden:true];
    [UIView animateWithDuration:duration animations:^{
        if (animationBlock != nil) {
            animationBlock();
        }
        self.imageView.frame = [self getImageActualFrame:self.showPictureSize];
    } completion:^(BOOL finished) {
        if (finished) {
            if (completionBlock) {
                completionBlock();
            }
        }
        self.showAnim = false;
    }];
}

- (void)animationDismissWithToRect:(CGRect)rect duration:(CGFloat)duration animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completionBlock {
    
    // 隐藏进度视图
    self.progressView.hidden = true;
    [UIView animateWithDuration:duration animations:^{
        if (animationBlock) {
            animationBlock();
        }
        CGRect toRect = rect;
        toRect.origin.y += self.offsetY;
        // 这一句话用于在放大的时候去关闭
        toRect.origin.x += self.contentOffset.x;
        self.imageView.frame = toRect;
    } completion:^(BOOL finished) {
        if (finished) {
            if (completionBlock) {
                completionBlock();
            }
        }
    }];
}

#pragma mark - 私有方法

- (void)layoutSubviews {
    [super layoutSubviews];
    self.progressView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
}

- (void)setShowAnim:(BOOL)showAnim {
    _showAnim = showAnim;
    if (showAnim == true) {
        self.progressView.hidden = true;
    }else {
        if (self.imageView.image) {
            self.progressView.hidden = true;
        } else {
            self.progressView.hidden = self.progressView.progress == 1;
        }
    }
}

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
    [self.imageView sd_cancelCurrentImageLoad];
    self.progressView.progress = 0.01;
    // 如果没有在执行动画，那么就显示出来
    if (self.isShowAnim == false) {
        // 显示出来
        self.progressView.hidden = false;
    }
    // 取消上一次的下载
    self.userInteractionEnabled = false;
    
  
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:self.placeholderImage options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        CGFloat progress = (CGFloat)receivedSize / expectedSize ;
        self.progressView.progress = progress;
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        if (error != nil) {
            [self.progressView showError];
        }else {
            if (image) {
                self.progressView.hidden = true;
                self.userInteractionEnabled = true;
                if (image != nil) {
                    // 计算图片的大小
                    [self setPictureSize:image.size];
                }else {
                    [self.progressView showError];
                }
                // 当下载完毕设置为1，因为如果直接走缓存的话，是不会走进度的 block 的
                // 解决在执行动画完毕之后根据值去判断是否要隐藏
                // 在执行显示的动画过程中：进度视图要隐藏，而如果在这个时候没有下载完成，需要在动画执行完毕之后显示出来
                self.progressView.progress = 1;
            }
        }
        
    }];
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    if (self.zoomScale == 1) {
        [UIView animateWithDuration:0.25 animations:^{
            CGPoint center = self.imageView.center;
            center.x = self.contentSize.width * 0.5;
            self.imageView.center = center;
        }];
    }
}

- (void)setLastContentOffset:(CGPoint)lastContentOffset {
    // 如果用户没有在拖动，并且绽放比 > 0.15
    if (!(self.dragging == false && _scale > 0.15)) {
        _lastContentOffset = lastContentOffset;
    }
}

- (void)setPictureSize:(CGSize)pictureSize {
    _pictureSize = pictureSize;
    if (CGSizeEqualToSize(pictureSize, CGSizeZero)) {
        return;
    }
    // 计算实际的大小
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat scale = screenW / pictureSize.width;
    CGFloat height = scale * pictureSize.height;
    self.showPictureSize = CGSizeMake(screenW, height);
}

- (void)setShowPictureSize:(CGSize)showPictureSize {
    _showPictureSize = showPictureSize;
    self.imageView.frame = [self getImageActualFrame:_showPictureSize];
    self.contentSize = self.imageView.frame.size;
}

- (CGRect)getImageActualFrame:(CGSize)imageSize {
    CGFloat x = 0;
    CGFloat y = 0;
    
    if (imageSize.height < [UIScreen mainScreen].bounds.size.height) {
        y = ([UIScreen mainScreen].bounds.size.height - imageSize.height) / 2;
    }
    return CGRectMake(x, y, imageSize.width, imageSize.height);
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center{
    CGRect zoomRect;
    zoomRect.size.height =self.frame.size.height / scale;
    zoomRect.size.width  =self.frame.size.width  / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    return zoomRect;
}

#pragma mark - 监听方法

- (void)doubleClick:(UITapGestureRecognizer *)ges {
    CGFloat newScale = 2;
    if (_doubleClicks) {
        newScale = 1;
    }
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[ges locationInView:ges.view]];
    [self zoomToRect:zoomRect animated:YES];
    _doubleClicks = !_doubleClicks;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    self.lastContentOffset = scrollView.contentOffset;
    // 保存 offsetY
    _offsetY = scrollView.contentOffset.y;
    
    // 正在动画
    if ([self.imageView.layer animationForKey:@"transform"] != nil) {
        return;
    }
    // 用户正在缩放
    if (self.zoomBouncing || self.zooming) {
        return;
    }
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    // 滑动到中间
    if (scrollView.contentSize.height > screenH) {
        // 代表没有滑动到底部
        if (_lastContentOffset.y > 0 && _lastContentOffset.y <= scrollView.contentSize.height - screenH) {
            return;
        }
    }
    _scale = fabs(_lastContentOffset.y) / screenH;
    
    // 如果内容高度 > 屏幕高度
    // 并且偏移量 > 内容高度 - 屏幕高度
    // 那么就代表滑动到最底部了
    if (scrollView.contentSize.height > screenH &&
        _lastContentOffset.y > scrollView.contentSize.height - screenH) {
        _scale = (_lastContentOffset.y - (scrollView.contentSize.height - screenH)) / screenH;
    }
    if (self.imageViewDelegate && [self.imageViewDelegate respondsToSelector:@selector(imageViewDidScrollTopOrBottom:)]) {
        [self.imageViewDelegate imageViewDidScrollTopOrBottom:self];
    }
    // 条件1：拖动到顶部再继续往下拖
    // 条件2：拖动到顶部再继续往上拖
    // 两个条件都满足才去设置 scale -> 针对于长图
    if (scrollView.contentSize.height > screenH) {
        // 长图
        if (scrollView.contentOffset.y < 0 || _lastContentOffset.y > scrollView.contentSize.height - screenH) {
            [_imageViewDelegate imageView:self scale:_scale];
        }
    }else {
        [_imageViewDelegate imageView:self scale:_scale];
    }
    
    // 如果用户松手
    if (scrollView.dragging == false) {
        if (_scale > 0.15 && _scale <= 1) {
            // 关闭
            [_imageViewDelegate imageViewTouch:self];
            // 设置 contentOffset
            [scrollView setContentOffset:_lastContentOffset animated:false];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.imageViewDelegate && [self.imageViewDelegate respondsToSelector:@selector(imageViewDidEndDragging:)]) {
        [self.imageViewDelegate imageViewDidEndDragging:self];
    }
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        if (self.imageViewDelegate && [self.imageViewDelegate respondsToSelector:@selector(imageViewDidEndDragging:)]) {
            [self.imageViewDelegate imageViewDidEndDragging:self];
        }
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGPoint center = _imageView.center;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height) ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    center.y = scrollView.contentSize.height * 0.5 + offsetY;
    _imageView.center = center;
    
    // 如果是缩小，保证在屏幕中间
    if (scrollView.zoomScale < scrollView.minimumZoomScale) {
        CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width) ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        center.x = scrollView.contentSize.width * 0.5 + offsetX;
        _imageView.center = center;
    }
}


@end

@interface XYImageProgressView ()

// 外界圆形
@property (nonatomic, strong) CAShapeLayer *circleLayer;
// 内部扇形
@property (nonatomic, strong) CAShapeLayer *fanshapedLayer;
// 错误
@property (nonatomic, strong) CAShapeLayer *errorLayer;
@end

@implementation XYImageProgressView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGRect rect = self.frame;
        rect.size = CGSizeMake(50, 50);
        self.frame = rect;
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    circleLayer.strokeColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8].CGColor;
    circleLayer.fillColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
    circleLayer.path = [self circlePath].CGPath;
    [self.layer addSublayer:circleLayer];
    self.circleLayer = circleLayer;
    
    CAShapeLayer *fanshapedLayer = [CAShapeLayer layer];
    fanshapedLayer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8].CGColor;
    [self.layer addSublayer:fanshapedLayer];
    self.fanshapedLayer = fanshapedLayer;
    
    CAShapeLayer *errorLayer = [CAShapeLayer layer];
    errorLayer.frame = self.bounds;
    // 旋转 45 度
    errorLayer.affineTransform = CGAffineTransformMakeRotation(M_PI_4);
    errorLayer.fillColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8].CGColor;
    errorLayer.path = [self errorPath].CGPath;
    [self.layer addSublayer:errorLayer];
    self.errorLayer = errorLayer;
    
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self updateProgressLayer];
}

- (void)showError {
    self.errorLayer.hidden = false;
    self.fanshapedLayer.hidden = true;
}

- (void)updateProgressLayer {
    self.errorLayer.hidden = true;
    self.fanshapedLayer.hidden = false;
    
    self.fanshapedLayer.path = [self pathForProgress:self.progress].CGPath;
}

- (UIBezierPath *)errorPath {
    CGFloat width = 30;
    CGFloat height = 5;
    UIBezierPath *path1 = [UIBezierPath bezierPathWithRect:CGRectMake(self.frame.size.width * 0.5 - height * 0.5, (self.frame.size.width - width) * 0.5, height, width)];
    UIBezierPath *path2 = [UIBezierPath bezierPathWithRect:CGRectMake((self.frame.size.width - width) * 0.5, self.frame.size.width * 0.5 - height * 0.5, width, height)];
    [path2 appendPath:path1];
    return path2;
}

- (UIBezierPath *)circlePath {
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5) radius:25 startAngle:0 endAngle:M_PI * 2 clockwise:true];
    path.lineWidth = 1;
    return path;
}

- (UIBezierPath *)pathForProgress:(CGFloat)progress {
    CGPoint center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    CGFloat radius = self.frame.size.height * 0.5 - 2.5;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint: center];
    [path addLineToPoint:CGPointMake(self.frame.size.width * 0.5, center.y - radius)];
    [path addArcWithCenter:center radius: radius startAngle: -M_PI / 2 endAngle: -M_PI / 2 + M_PI * 2 * progress clockwise:true];
    [path closePath];
    path.lineWidth = 1;
    return path;
}


@end
