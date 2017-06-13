//
//  XYCutVideoView.m
//  XYVideoCut
//
//  Created by mofeini on 16/11/14.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYCutVideoView.h"


@interface XYCutVideoView ()

@property (nonatomic, weak) XYVideoPlayerView *videoPlayerView;
@property (nonatomic, weak) ICGVideoTrimmerView *cutView;

@end

@implementation XYCutVideoView

+ (instancetype)cutVideoViewWithCompletionHandle:(void (^)(ICGVideoTrimmerView * _Nonnull, XYVideoPlayerView * _Nonnull))block {
    
    XYCutVideoView *view = [[self alloc] init];
    if (block) {
        block(view.cutView, view.videoPlayerView);
    }
    
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame {

    if (self = [super initWithFrame:frame]) {
        
        XYVideoPlayerView *videoPlayerView = [[XYVideoPlayerView alloc] init];
        videoPlayerView.backgroundColor = [UIColor colorWithRed:56/255.0 green:55/255.0 blue:53/255.0 alpha:1.0];
        [self addSubview:videoPlayerView];
        self.videoPlayerView = videoPlayerView;
        
        ICGVideoTrimmerView *cutView = [ICGVideoTrimmerView thrimmerViewWithAsset:nil];
        [self addSubview:cutView];
        self.cutView = cutView;
        cutView.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 100);
        cutView.rightOverlayViewColor = videoPlayerView.backgroundColor;
        cutView.leftOverlayViewColor = videoPlayerView.backgroundColor;
        
        self.videoPlayerView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cutView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)layoutSubviews {

    [super layoutSubviews];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_videoPlayerView, _cutView);
    NSDictionary *metrics = @{@"margin": @0, @"cutViewH": @100};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_videoPlayerView]|" options:NSLayoutAttributeLeft | NSLayoutAttributeRight metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[_cutView]|" options:kNilOptions metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_videoPlayerView][_cutView(cutViewH)]|" options:kNilOptions metrics:metrics views:views]];
    
    [self layoutIfNeeded];
}


#pragma mark - Private Method
// 绘制一个渐变的颜色，作为背景色。定义一个配置函数
-(void)setupCAGradientLayer:(CAGradientLayer *)gradient{
    UIColor *colorOne = [UIColor colorWithRed:60/255.0 green:59/255.0 blue:65/255.0 alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithRed:57/255.0 green:80/255.0 blue:96/255.0 alpha:1.0];
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, (id)colorTwo.CGColor, nil];
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    gradient.colors = colors;
    gradient.locations = locations;
}


- (void)dealloc {

    NSLog(@"%s", __func__);
}
@end
