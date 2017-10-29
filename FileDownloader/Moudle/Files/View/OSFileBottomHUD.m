//
//  OSFileBottomHUD.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileBottomHUD.h"

@interface OSFileBottomHUD ()

@property (nonatomic, strong) UIWindow *parentWindow;
@property (nonatomic, assign) CGRect hideRect;
@property (nonatomic, weak) UIView *toView;

@end

@implementation OSFileBottomHUD

- (instancetype)initWithView:(UIView *)view {
    if (self = [super initWithFrame:CGRectZero]) {
        NSAssert(view, @"view do not nil");
        self.toView = view;
    }
    return self;
}

- (void)showHUDWithFrame:(CGRect)frame completion:(void (^)(void))completion{
    [UIView animateWithDuration:0.2 animations:^{
        self.parentWindow.hidden = NO;
        CGRect hudFrame = self.parentWindow.frame;
        if (CGRectIsEmpty(frame)) {
            hudFrame = self.frame;
        }
        else {
            hudFrame = frame;
        }
        
        self.parentWindow.frame = hudFrame;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
   
}

- (void)hideHudCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.parentWindow.frame;
        frame.origin.y = self.toView.frame.size.height;
        self.parentWindow.frame =  frame;
    } completion:^(BOOL finished) {
        self.parentWindow.hidden = YES;
        if (completion) {
            completion();
        }
    }];
    
}

- (UIWindow *)parentWindow {
    if (!_parentWindow) {
        
        UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, self.toView.frame.size.height, self.toView.frame.size.width, self.frame.size.height)];
        _parentWindow = window;
        UIViewController *vc = [[UIViewController alloc] init];
        window.rootViewController = vc;
        UIView *view = [[UIView alloc] init];
        [vc.view addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [vc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:kNilOptions metrics:nil views:@{@"view": view}]];
        [vc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:kNilOptions metrics:nil views:@{@"view": view}]];
        view.backgroundColor = [UIColor blueColor];
        window.hidden = NO;
    }
    return _parentWindow;
}
@end
