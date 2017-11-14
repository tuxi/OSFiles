//
//  MBProgressHUD+BBHUD.h
//  Boobuz
//
//  Created by xiaoyuan on 14/11/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import <MBProgressHUD.h>

typedef void(^BBHUDActionCallBack)(MBProgressHUD *hud);

@interface UIView (BBHUDExtension)

#pragma mark *** Text hud ***

- (MBProgressHUD *)bb_hud;

/// 显示文本样式的hud, 默认显示在当前控制器view上
- (void)bb_showMessage:(NSString *)message;
- (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime;
- (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime
                offset:(CGPoint)offset;

#pragma mark *** Activity hud ***

/// 显示菊花样式的hud
- (void)bb_showActivityHud;
- (void)bb_showActivityMessage:(NSString *)message;
- (void)bb_showActivityHudDelayTime:(NSInteger)delayTime;
- (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime;
- (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime
                        offset:(CGPoint)offset;

/// 显示菊花和取消按钮的loading，不会自动隐藏，需要手动调用hide隐藏
- (void)bb_showActivityHudWithActionCallBack:(BBHUDActionCallBack)callBack;
/// 显示菊花和取消按钮的loading，不会自动隐藏，需要手动调用hide隐藏
/// @param message 菊花下面显示的文本
/// @param callBack 触发取消按钮的回调
- (void)bb_showActivityHudWithMessage:(NSString *)message
                       actionCallBack:(BBHUDActionCallBack)callBack;

#pragma mark *** Custom hud ***

/// 显示自定义样式的hud
/// @param image hud上显示的图片
/// @param message hud上显示的文本
- (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message;
- (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                    offset:(CGPoint)offset;

#pragma mark *** Hide hud ***

- (void)bb_hideHUD;
- (void)bb_hideHUDWithMessage:(NSString *)message
                    hideAfter:(NSTimeInterval)afterSecond;
- (void)bb_hideHUDWithAfter:(NSTimeInterval)afterSecond;

@end

@interface MBProgressHUD (BBHUD)

#pragma mark *** Text hud ***

/// 显示文本样式的hud, 默认显示在当前控制器view上
+ (void)bb_showMessage:(NSString *)message;
+ (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime;
+ (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime
              isWindow:(BOOL)isWindow;
+ (void)bb_showMessage:(NSString *)message
             delayTime:(NSInteger)delayTime
                toView:(UIView *)view;

#pragma mark *** Activity hud ***

/// 显示菊花样式的hud
+ (void)bb_showActivityHud;
+ (void)bb_showActivityHudDelayTime:(NSInteger)delayTime;
+ (void)bb_showActivityHudToView:(UIView *)view;
+ (void)bb_showActivityHudDelayTime:(NSInteger)delayTime
                             toView:(UIView *)view;
+ (void)bb_showActivityMessage:(NSString*)message;
+ (void)bb_showActivityMessage:(NSString*)message
                      isWindow:(BOOL)isWindow
                     delayTime:(NSInteger)delayTime;
+ (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime
                        toView:(UIView *)view;
+ (void)bb_showActivityMessage:(NSString*)message
                     delayTime:(NSInteger)delayTime
                        toView:(UIView *)view
                        offset:(CGPoint)offset;
/// 显示菊花和取消按钮的loading，不会自动隐藏，需要手动调用hide隐藏
+ (void)bb_showActivityHudWithActionCallBack:(BBHUDActionCallBack)callBack;
/// 显示菊花和取消按钮的loading，不会自动隐藏，需要手动调用hide隐藏
/// @param message 菊花下面显示的文本
/// @param callBack 触发取消按钮的回调
+ (void)bb_showActivityHudWithMessage:(NSString *)message
                       actionCallBack:(BBHUDActionCallBack)callBack;

#pragma mark *** Custom hud ***

/// 显示自定义样式的hud, 默认显示在window上
+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message;
/// 显示自定义样式的hud
/// @param image hud上显示的图片
/// @param message hud上显示的文本
/// @param isWindow hud 如果是YES显示在appliction的window上，否则显示在当前topViewController上
+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                  isWindow:(BOOL)isWindow;
+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                    toView:(UIView *)view;
+ (void)bb_showCustomImage:(UIImage *)image
                   message:(NSString *)message
                    toView:(UIView *)view
                    offset:(CGPoint)offset;

#pragma mark *** Hide hud ***

/// 隐藏当前window显示的hud和当前topViewController显示的hud
+ (void)bb_hideHUD;

@end
