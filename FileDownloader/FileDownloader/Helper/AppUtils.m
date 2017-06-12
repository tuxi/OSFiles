//
//  AppUtils.m
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "AppUtils.h"

@implementation AppUtils

+ (UIViewController *)topViewController {
    id<UIApplicationDelegate> delegate = (id<UIApplicationDelegate>)[UIApplication sharedApplication].delegate;
    UINavigationController * navigationController = (UINavigationController *)delegate.window.rootViewController;
    if ([navigationController isKindOfClass:[UINavigationController class]]) {
        UIViewController * currentViewController = [navigationController topViewController];
        return currentViewController;
    }
    return nil;
}

@end
