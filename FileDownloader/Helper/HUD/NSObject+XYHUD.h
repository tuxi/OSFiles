//
//  NSObject+XYHUD.h
//  MiaoLive
//
//  Created by mofeini on 16/11/16.
//  Copyright © 2016年 MiaoLive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface NSObject (XYHUD)

/**
 * @explain 显示提示信息
 *
 * @param   info  展示传入信息
 */
- (void)showInfo:(NSString *)info;


@property (nonatomic, weak, readonly) MBProgressHUD *hud;


/**
 * @explain 显示提示信息
 *
 * @param   meeeage  提示信息的内容
 */
- (void)xy_showMessage:(NSString *)meeeage;

/**
 * @explain 显示提示信息
 *
 * @param   view  将提示信息显示在哪个view上
 * @param   message  提示信息的内容
 */
- (void)xy_showHudToView:(UIView *)view message:(NSString *)message;
- (void)xy_showHudToView:(UIView *)view message:(NSString *)message offsetY:(CGFloat)offsetY;

/**
 * @explain 隐藏hud
 */
- (void)hideHud;
@end
