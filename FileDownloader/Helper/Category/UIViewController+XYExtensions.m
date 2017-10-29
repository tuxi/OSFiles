//
//  UIViewController+XYExtensions.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UIViewController+XYExtensions.h"

@implementation UIViewController (XYExtensions)


+ (UIViewController *)xy_topViewController {
    UIViewController *resultVC;
    resultVC = [self _topViewController:[[UIApplication sharedApplication].delegate.window rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

+ (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

+ (UINavigationController *)xy_currentNavigationController {
    UIViewController *rootViewController = (UINavigationController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nac = (UINavigationController *)rootViewController;
        return nac;
    }
    else if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabc = (UITabBarController *)rootViewController;
        UINavigationController *nac = tabc.selectedViewController;
        return nac;
    }
    return nil;
}



@end
