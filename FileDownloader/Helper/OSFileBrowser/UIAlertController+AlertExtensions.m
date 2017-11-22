//
//  UIAlertController+AlertExtensions.m
//  Boobuz
//
//  Created by xiaoyuan on 13/11/2017.
//  Copyright © 2017 erlinyou.com. All rights reserved.
//

#import "UIAlertController+AlertExtensions.h"

@implementation UIAlertController (AlertExtensions)

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}
#endif
@end
