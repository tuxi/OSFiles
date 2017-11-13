//
//  NSObject+XYHUD.h
//  MiaoLive
//
//  Created by mofeini on 16/11/16.
//  Copyright © 2016年 MiaoLive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

typedef void(^HUDCancelCallBack)(MBProgressHUD *hud);

@interface NSObject (XYHUD)

@property (nonatomic, readonly) MBProgressHUD *hud;

- (void)xy_showMessage:(NSString *)meeeage;
- (void)xy_showHudToView:(UIView *)view message:(NSString *)message;
- (void)xy_showHudToView:(UIView *)view message:(NSString *)message offsetY:(CGFloat)offsetY;
- (void)xy_showHudWithMessage:(NSString *)message cancelCallBack:(HUDCancelCallBack)callBack;
- (void)hideHud;

@end

