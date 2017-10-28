//
//  UIViewController+XYHUD.m
//  MiaoLive
//
//  Created by mofeini on 16/11/18.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "UIViewController+XYHUD.h"
#import <objc/runtime.h>

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static const void *hudKey = &hudKey;

@implementation UIViewController (XYHUD)

#pragma mark - 动态绑定
- (void)setHud:(MBProgressHUD *)hud {
    objc_setAssociatedObject(self, hudKey, hud, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MBProgressHUD *)hud {

    return objc_getAssociatedObject(self, hudKey);
}


- (void)xy_hideHud {

    if (self.hud) {
        [self.hud hideAnimated:YES];
        self.hud = nil;
    }
}

- (void)xy_showHud {
    
    // 转菊花
    //初始化进度框，置于当前的View当中
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.color = [UIColor blackColor];
    self.hud.backgroundColor = self.view.backgroundColor;
    //如果设置此属性则当前的view置于后台
    self.hud.dimBackground = YES;
}


- (void)xy_showMessage:(NSString *)meeeage {

    // 显示提示信息
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.userInteractionEnabled = NO;
    hud.mode = MBProgressHUDModeText;
    [hud.label setText:meeeage];
    hud.label.numberOfLines = 0;
    hud.margin = 10.0f;
    [hud setRemoveFromSuperViewOnHide:YES];
    [hud hideAnimated:YES afterDelay:2.0];
}

- (void)xy_showHudToView:(UIView *)view message:(NSString *)message {
    
    // 显示提示的信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    [hud.label setText:message];
    [view addSubview:hud];
    [hud showAnimated:YES];
    
}

- (void)xy_showHudToView:(UIView *)view message:(NSString *)message offsetY:(CGFloat)offsetY {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
    [hud.label setText:message];
    hud.margin = 10.0f;
    [hud setOffset:CGPointMake(hud.offset.x, offsetY)];
    [view addSubview:hud];
    [hud showAnimated:YES];
    [self setHud:hud];
}

@end
