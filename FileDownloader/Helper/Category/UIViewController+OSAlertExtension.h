//
//  UIViewController+OSAlertExtension.h
//  FileDownloader
//
//  Created by Swae on 2017/10/27.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (OSAlertExtension)

- (void)alertControllerWithTitle:(NSString *)title content:(NSString *)content placeholder:(NSString *)placeholder blk:(void (^)(UITextField *))blk;
- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message okBlk:(void (^)(void))okBlk cancelBlk:(void (^)(void))cancelBlk;
- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message content:(NSString *)content placeholder:(NSString *)placeholder keyboardType:(UIKeyboardType)keyboardType blk:(void (^)(UITextField *))blk;
- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message okBlk:(void (^)(void))okBlk;
@end
