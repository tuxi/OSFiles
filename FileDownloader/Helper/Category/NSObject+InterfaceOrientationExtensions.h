//
//  NSObject+InterfaceOrientationExtensions.h
//  Boobuz
//
//  Created by xiaoyuan on 28/09/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, InterfaceOrientation) {
    InterfaceOrientationUnKnow,
    InterfaceOrientationLandscape, // 横屏
    InterfaceOrientationPortrait   // 竖屏
};

@interface NSObject (InterfaceOrientationExtensions)

/**
 *  强制屏幕转屏
 *
 *  @param orientation 屏幕方向
 *  @param orientationBlock 屏幕方向改变完成的回调
 */
- (void)applyInterfaceOrientation:(UIDeviceOrientation)orientation interfaceOrientationDidChangeBlock:(void (^)(InterfaceOrientation orientation))orientationBlock;

@end
