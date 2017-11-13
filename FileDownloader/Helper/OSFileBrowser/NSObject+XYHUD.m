//
//  NSObject+XYHUD.m
//  MiaoLive
//
//  Created by mofeini on 16/11/16.
//  Copyright © 2016年 MiaoLive. All rights reserved.
//

#import "NSObject+XYHUD.h"
#import <objc/runtime.h>
#import "UIViewController+XYExtensions.h"

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static const void *hudKey = &hudKey;

@implementation NSObject (XYHUD)

- (void)setHud:(MBProgressHUD *)hud {
    
    objc_setAssociatedObject(self, hudKey, hud, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCancelOption:(HUDCancelCallBack)cancelOption {
    objc_setAssociatedObject(self, @selector(cancelOption), cancelOption, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HUDCancelCallBack)cancelOption {
    return objc_getAssociatedObject(self, _cmd);
}

- (MBProgressHUD *)hud {
    
    return objc_getAssociatedObject(self, hudKey);
}


- (void)hideHud {
    
    [self.hud hideAnimated:YES];
}

- (void)xy_showMessage:(NSString *)meeeage {
    
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    [self xy_showHudToView:window message:meeeage];
    self.hud.mode = MBProgressHUDModeText;
    [self.hud hideAnimated:YES afterDelay:2.0];
}

- (void)xy_showHudToView:(UIView *)view message:(NSString *)message {
    
    [self xy_showHudToView:view message:message offsetY:0];
    
}

- (void)xy_showHudToView:(UIView *)view message:(NSString *)message offsetY:(CGFloat)offsetY {
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    };
    [self.hud.label setText:message];
    self.hud.label.numberOfLines = 0;
    self.hud.margin = 10.0f;
    [self.hud setOffset:CGPointMake(self.hud.offset.x, offsetY)];
}

- (void)xy_showHudWithMessage:(NSString *)message cancelCallBack:(HUDCancelCallBack)callBack {
    if (!self.hud) {
        self.hud = [MBProgressHUD showHUDAddedTo:[UIViewController xy_topViewController].view animated:YES];
    }
    self.cancelOption = callBack;
    [self.hud.button setTitle:@"Cancel" forState:UIControlStateNormal];
    self.hud.mode = MBProgressHUDModeDeterminate;
    [self.hud.button addTarget:self action:@selector(cancelOperation:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)cancelOperation:(id)sender {
    if (self.cancelOption) {
        self.cancelOption(sender);
    }
    [sender hideAnimated:YES afterDelay:1.0];
    self.hud = nil;
}

@end

