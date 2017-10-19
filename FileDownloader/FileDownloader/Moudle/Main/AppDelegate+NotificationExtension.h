//
//  AppDelegate+NotificationExtension.h
//  FileDownloader
//
//  Created by Swae on 2017/10/20.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (NotificationExtension)

/// 注册本地通知
- (void)registerLocalNotificationWithBlock:(void (^)(UILocalNotification *))block;
/// 发送本地通知
- (void)sendLocalNotificationWithMessage:(NSString *)message;

@end
