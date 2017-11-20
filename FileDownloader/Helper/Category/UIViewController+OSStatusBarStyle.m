//
//  UIViewController+OSStatusBarStyle.m
//  FileBrowser
//
//  Created by xiaoyuan on 20/11/2017.
//  Copyright © 2017 xiaoyuan. All rights reserved.
//

#import "UIViewController+OSStatusBarStyle.h"
#import <objc/runtime.h>

static const char * OSStatusBarStyleKey = "JKR_STATUS_LIGHT";

@implementation UIViewController (OSStatusBarStyle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        OSSwizzleInstanceMethod(class,
                                @selector(preferredStatusBarStyle),
                                @selector(os_preferredStatusBarStyle));
        
    });
}



- (void)setOs_statusBarStyle:(UIStatusBarStyle)os_statusBarStyle {
    objc_setAssociatedObject(self, OSStatusBarStyleKey, [NSNumber numberWithInteger:os_statusBarStyle], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self preferredStatusBarStyle];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)os_statusBarStyle {
    return [objc_getAssociatedObject(self, OSStatusBarStyleKey) integerValue];
}

- (UIStatusBarStyle)os_preferredStatusBarStyle {
    NSNumber *num = objc_getAssociatedObject(self, OSStatusBarStyleKey);
    if (num) {
        return [num integerValue];
    }
    return [self os_preferredStatusBarStyle];;
}


@end
