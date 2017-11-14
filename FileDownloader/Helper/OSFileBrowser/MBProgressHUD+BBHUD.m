//
//  MBProgressHUD+BBHUD.m
//  Boobuz
//
//  Created by xiaoyuan on 14/11/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import "MBProgressHUD+BBHUD.h"
#import <objc/runtime.h>
#import "UIViewController+XYExtensions.h"

#define BB_DEFAULT_TO_VIEW(isWindow) isWindow ? (UIView *)[UIApplication sharedApplication].delegate.window : [UIViewController xy_topViewController].view
#define BB_HUD_VIEW_SELF [MBProgressHUD HUDForView:self]
#define BB_HUD_NULL_VIEW view ?: (UIView *)[UIApplication sharedApplication].delegate.window

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

static const CGFloat BBToastDefaultDuration = 2.0;

@interface UIView ()

- (void)setBb_hudCancelOption:(BBHUDActionCallBack)cancelOption;
- (void)bb_cancelOperationAction:(id)sender;

@end

@implementation MBProgressHUD (BBHUD)

////////////////////////////////////////////////////////////////////////
#pragma mark - Activity
////////////////////////////////////////////////////////////////////////

+ (void)bb_showActivityHud {
    [self bb_showActivityHudToView:nil];
}

+ (void)bb_showActivityHudToView:(UIView *)view {
    [self bb_showActivityHudDelayTime:0 toView:view];
}

+ (void)bb_showActivityHudDelayTime:(NSInteger)delayTime {
    [self bb_showActivityHudDelayTime:delayTime toView:nil];
}

+ (void)bb_showActivityHudDelayTime:(NSInteger)delayTime
                             toView:(UIView *)view {
    [self bb_showActivityMessage:nil delayTime:delayTime toView:view];
}

+ (void)bb_showActivityMessage:(NSString*)message  {
    [self bb_showActivityMessage:message isWindow:YES delayTime:0];
}

+ (void)bb_showActivityMessage:(NSString*)message
                      isWindow:(BOOL)isWindow
                     delayTime:(NSInteger)delayTime {
    [self bb_showActivityMessage:message
                       delayTime:delayTime
                          toView:BB_DEFAULT_TO_VIEW(isWindow)];
}

+ (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime
                        toView:(UIView *)view {
    [self bb_showActivityMessage:message
                       delayTime:delayTime
                          toView:view
                          offset:CGPointZero];
}

+ (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime
                        toView:(UIView *)view
                        offset:(CGPoint)offset {
    MBProgressHUD *hud  = [self bb_hudWithMessage:message
                                           toView:view
                                           offset:offset];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.textColor = [UIColor blackColor];
    hud.square = YES;
    if (delayTime > 0) {
        [hud hideAnimated:YES afterDelay:delayTime];
    }
}

+ (void)bb_showActivityHudWithActionCallBack:(BBHUDActionCallBack)callBack {
    [self bb_showActivityHudWithMessage:nil actionCallBack:callBack];
}

+ (void)bb_showActivityHudWithMessage:(NSString *)message
                       actionCallBack:(BBHUDActionCallBack)callBack {
    [self bb_showActivityHudWithMessage:message toView:nil actionCallBack:callBack];
}

+ (void)bb_showActivityHudWithMessage:(NSString *)message
                               toView:(UIView *)view
                       actionCallBack:(BBHUDActionCallBack)callBack {
    MBProgressHUD *hud = [self bb_hudWithMessage:message toView:view offset:CGPointZero];
    view = BB_HUD_NULL_VIEW;
    view.bb_hudCancelOption = callBack;
    [hud.button setTitle:@"Cancel" forState:UIControlStateNormal];
    [hud.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [hud.button addTarget:view
                   action:@selector(bb_cancelOperationAction:)
         forControlEvents:UIControlEventTouchUpInside];
}



////////////////////////////////////////////////////////////////////////
#pragma mark - CustomView
////////////////////////////////////////////////////////////////////////

+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message {
    [self bb_showCustomImage:image
                     message:message
                    isWindow:YES];
}

+ (void)bb_showCustomImage:(UIImage *)image
                message:(NSString *)message
               isWindow:(BOOL)isWindow {
    [self bb_showCustomImage:image
                     message:message
                      toView:BB_DEFAULT_TO_VIEW(isWindow)];
}

+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                    toView:(UIView *)view {
    [self bb_showCustomImage:image message:message toView:view offset:CGPointZero];
}

+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                    toView:(UIView *)view
                    offset:(CGPoint)offset {
    
    MBProgressHUD *hud = [self bb_hudWithMessage:message toView:view offset:offset];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = [[UIImageView alloc] initWithImage:image];
    [hud hideAnimated:YES afterDelay:BBToastDefaultDuration];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Text
////////////////////////////////////////////////////////////////////////

+ (void)bb_showMessage:(NSString *)message {
    [self bb_showMessage:message delayTime:BBToastDefaultDuration isWindow:NO];
}

+ (void)bb_showMessage:(NSString *)message delayTime:(NSInteger)delayTime {
    [self bb_showMessage:message delayTime:delayTime toView:nil];
}

+ (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime
                toView:(UIView *)view {
    [self bb_showMessage:message delayTime:delayTime toView:view offSet:CGPointZero];
}

+ (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime
                toView:(UIView *)view
                offSet:(CGPoint)offset {
    if (delayTime <= 0.0) {
        delayTime = 2.0;
    }
    MBProgressHUD *hud = [self bb_hudWithMessage:message toView:view offset:offset];
    hud.mode = MBProgressHUDModeText;
    [hud hideAnimated:YES afterDelay:delayTime];
}

+ (void)bb_showMessage:(NSString *)message
          delayTime:(NSInteger)delayTime
           isWindow:(BOOL)isWindow {
    [self bb_showMessage:message
               delayTime:delayTime
                  toView:BB_DEFAULT_TO_VIEW(isWindow)];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Hide
////////////////////////////////////////////////////////////////////////

+ (void)bb_hideHUD {
    UIView *windowView = (UIView *)[UIApplication sharedApplication].delegate.window;
    [self hideHUDForView:windowView animated:YES];
    [self hideHUDForView:[UIViewController xy_topViewController].view animated:YES];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Init
////////////////////////////////////////////////////////////////////////

+ (MBProgressHUD *)bb_hudWithMessage:(NSString *)message
                                         isWindow:(BOOL)isWindow {
    MBProgressHUD *hud = [self bb_hudWithMessage:message toView:BB_DEFAULT_TO_VIEW(isWindow) offset:CGPointZero];
    return hud;
}

+ (MBProgressHUD *)bb_hudWithMessage:(NSString *)message toView:(UIView *)view offset:(CGPoint)offset {
    view = BB_HUD_NULL_VIEW;
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
    // 修改样式，否则等待框背景色将为半透明
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    // 设置等待框背景色为黑色
    hud.bezelView.backgroundColor = [UIColor blackColor];
    hud.removeFromSuperViewOnHide = YES;
    // 设置菊花框为白色
    [UIActivityIndicatorView appearanceWhenContainedIn:[MBProgressHUD class], nil].color = [UIColor whiteColor];
    [view addSubview:hud];
    hud.label.font = [UIFont systemFontOfSize:15.0f];
    // 设置间距为10.f
    hud.margin = 10.0f;
    // 方形
    hud.square = NO;
    // 设置内部控件的颜色，包括button的文本颜色，边框颜色，label的文本颜色等
    hud.contentColor = [UIColor whiteColor];
    [hud setOffset:offset];
    [hud showAnimated:YES];
    hud.label.text = message;
    return hud;
}

@end

@implementation UIView (BBHUDExtension)

- (MBProgressHUD *)bb_hud {
   return [MBProgressHUD HUDForView:self];
}

#pragma mark *** Text hud ***

/// 显示文本样式的hud, 默认显示在当前控制器view上
- (void)bb_showMessage:(NSString *)message {
    [self bb_showMessage:message delayTime:0];
}
- (void)bb_showMessage:(NSString *)message
                        delayTime:(NSInteger)delayTime {
    [self bb_showMessage:message
               delayTime:delayTime
                  offset:CGPointZero];
}

- (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime
                offset:(CGPoint)offset {
    [MBProgressHUD bb_showMessage:message
                        delayTime:delayTime
                           toView:self
                           offSet:offset];
}

#pragma mark *** Activity hud ***

- (void)bb_showActivityHud {
    [self bb_showActivityMessage:nil];
}

- (void)bb_showActivityMessage:(NSString *)message {
    [self bb_showActivityMessage:message delayTime:0];
}

- (void)bb_showActivityHudDelayTime:(NSInteger)delayTime {
    [self bb_showActivityMessage:nil delayTime:delayTime];
}

- (void)bb_showActivityHudWithActionCallBack:(BBHUDActionCallBack)callBack {
    [self bb_showActivityHudWithMessage:nil actionCallBack:callBack];
}

- (void)bb_showActivityMessage:(NSString*)message delayTime:(NSInteger)delayTime {
    [self bb_showMessage:message delayTime:delayTime offset:CGPointZero];
}

- (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime
                        offset:(CGPoint)offset {
    [MBProgressHUD bb_showActivityMessage:message
                                delayTime:delayTime
                                   toView:self
                                   offset:offset];
}

- (void)bb_showActivityHudWithMessage:(NSString *)message
                       actionCallBack:(BBHUDActionCallBack)callBack {
    [MBProgressHUD bb_showActivityHudWithMessage:message toView:self actionCallBack:callBack];
}


#pragma mark *** Custom hud ***

- (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message {
    [MBProgressHUD bb_showCustomImage:image
                              message:message
                               toView:self
                               offset:CGPointZero];
}

- (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                    offset:(CGPoint)offset {
    [self bb_showCustomImage:image
                     message:message
                      offset:offset];
}

- (void)bb_hideHUD {
    [MBProgressHUD hideHUDForView:self animated:YES];
}

- (void)bb_hideHUDWithMessage:(NSString *)message
                    hideAfter:(NSTimeInterval)afterSecond {
    MBProgressHUD *hud = [self bb_hud];
    if (!hud) {
        return;
    }
    hud.label.text = message;
    [hud hideAnimated:YES afterDelay:afterSecond];
}

- (void)bb_hideHUDWithAfter:(NSTimeInterval)afterSecond {
    [self bb_hideHUDWithMessage:nil hideAfter:afterSecond];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Action
////////////////////////////////////////////////////////////////////////

- (void)bb_cancelOperationAction:(id)sender {
    if (self.bb_hudCancelOption) {
        self.bb_hudCancelOption([self bb_hud]);
    }
    
    [self bb_hideHUDWithAfter:1.0];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Set \ get
////////////////////////////////////////////////////////////////////////

- (void)setBb_hudCancelOption:(BBHUDActionCallBack)cancelOption {
    objc_setAssociatedObject(self, @selector(bb_hudCancelOption), cancelOption, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BBHUDActionCallBack)bb_hudCancelOption {
    return objc_getAssociatedObject(self, _cmd);
}

@end

