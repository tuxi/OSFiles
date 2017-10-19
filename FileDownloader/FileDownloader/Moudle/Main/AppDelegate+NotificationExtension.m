//
//  AppDelegate+NotificationExtension.m
//  FileDownloader
//
//  Created by Swae on 2017/10/20.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "AppDelegate+NotificationExtension.h"
#import <objc/runtime.h>

@interface AppDelegate ()

/// 通知的内容
@property (nonatomic, strong) NSString *notifyMessage;
/// 本地通知
@property (nonatomic, strong) UILocalNotification *localNotification;

@end

@implementation AppDelegate (NotificationExtension)

////////////////////////////////////////////////////////////////////////
#pragma mark - UIApplicationDelegate 与本地通知相关的代理方法
////////////////////////////////////////////////////////////////////////

/// 此方法是本地通知会触发的方法，当点击通知横幅进入app时会调用
- (void)application:(UIApplication *)application didReceiveLocalNotification:(nonnull UILocalNotification *)notification {
    
    // 取消所有通知
    [application cancelAllLocalNotifications];
    [[[UIAlertView alloc] initWithTitle:@"下载通知" message:self.notifyMessage delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil] show];
    
    // 点击通知后，就让图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
}

/// 当有电话进来或者锁屏，此时应用程会挂起，调用此方法，此方法一般做挂起前的工作，比如关闭网络，保存数据
- (void)applicationWillResignActive:(UIApplication *)application {
    // 图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)registerLocalNotificationWithBlock:(void (^)(UILocalNotification *))block {
    
    [self localNotification];
    
    if (block) {
        block(self.localNotification);
    }
}

/// 发送本地通知
- (void)sendLocalNotificationWithMessage:(NSString *)message {
    self.notifyMessage = message;
    [[UIApplication sharedApplication] scheduleLocalNotification:self.localNotification];
}

- (void)setNotifyMessage:(NSString *)notifyMessage {
    objc_setAssociatedObject(self, @selector(notifyMessage), notifyMessage, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)notifyMessage {
    
    return objc_getAssociatedObject(self, @selector(notifyMessage)) ?: @"下载完成了";
}

- (void)setLocalNotification:(UILocalNotification *)localNotification {
    objc_setAssociatedObject(self, @selector(localNotification), localNotification, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILocalNotification *)localNotification {
    
    UILocalNotification *localNot = objc_getAssociatedObject(self, @selector(localNotification));
    
    if (localNot == nil) {
        self.localNotification = (localNot = [UILocalNotification new]);
        localNot.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
        localNot.alertAction = nil;
        localNot.soundName = UILocalNotificationDefaultSoundName;
        localNot.alertBody = self.notifyMessage;
        localNot.applicationIconBadgeNumber = 1;
        localNot.repeatInterval = 0;
    }
    return localNot;
}

@end
