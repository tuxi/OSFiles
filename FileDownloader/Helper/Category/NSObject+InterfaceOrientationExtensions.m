//
//  NSObject+InterfaceOrientationExtensions.m
//  Boobuz
//
//  Created by xiaoyuan on 28/09/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import "NSObject+InterfaceOrientationExtensions.h"
#import <objc/runtime.h>

@interface NSObject ()

@property (nonatomic) void (^ interfaceOrientationDidChangeBlock)(InterfaceOrientation orientation);

@end

@implementation NSObject (InterfaceOrientationExtensions)

////////////////////////////////////////////////////////////////////////
#pragma mark - 强制屏幕旋转
////////////////////////////////////////////////////////////////////////

- (void)applyInterfaceOrientation:(UIDeviceOrientation)orientation interfaceOrientationDidChangeBlock:(void (^)(InterfaceOrientation orientation))orientationBlock {
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    if (currentDevice.orientation == orientation) {
        return;
    }
    

    SEL selector = NSSelectorFromString(@"setOrientation:");
   
    if (![currentDevice respondsToSelector:selector]) {
        return;
    }
    self.interfaceOrientationDidChangeBlock = orientationBlock;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:currentDevice];
    int par = orientation;
    // 从2开始是因为0 1 两个参数已经被selector和target占用
    [invocation setArgument:&par atIndex:2];
    [invocation invoke];
    [self setOrientationDidChange:orientation];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (UIDeviceOrientation)convertToUIDeviceOrientation:(InterfaceOrientation)orientation {
    UIDeviceOrientation io = UIDeviceOrientationUnknown;
    if (orientation == InterfaceOrientationLandscape) {
        // 竖屏
        io = UIDeviceOrientationLandscapeLeft;
    }
    else if (orientation == InterfaceOrientationPortrait) {
        // 横屏
        io = UIDeviceOrientationPortrait;
    }
    return io;
}

- (InterfaceOrientation)convertToInterfaceOrientation:(UIDeviceOrientation)orientation {
    InterfaceOrientation io = InterfaceOrientationUnKnow;
    if (orientation == UIDeviceOrientationLandscapeRight || orientation == UIDeviceOrientationLandscapeLeft) {
        // 竖屏
        io = InterfaceOrientationLandscape;
    }
    else if (orientation == UIDeviceOrientationPortrait) {
        // 横屏
        io = InterfaceOrientationPortrait;
    }
    return io;
}


- (void)setOrientationDidChange:(UIDeviceOrientation)orientation {
    InterfaceOrientation io = [self convertToInterfaceOrientation:orientation];
    
    if (self.interfaceOrientationDidChangeBlock) {
        self.interfaceOrientationDidChangeBlock(io);
    }
}

- (void (^)(InterfaceOrientation *))interfaceOrientationDidChangeBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setInterfaceOrientationDidChangeBlock:(void (^)(InterfaceOrientation *))interfaceOrientationDidChangeBlock {
    objc_setAssociatedObject(self, @selector(interfaceOrientationDidChangeBlock), interfaceOrientationDidChangeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
