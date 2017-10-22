//
//  OSLoaclNotificationHelper.m
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSLoaclNotificationHelper.h"

@interface OSLoaclNotificationHelper ()

/// 本地通知
@property (nonatomic, strong) UILocalNotification *localNotification;

@end

@implementation OSLoaclNotificationHelper

@dynamic sharedInstance;

+ (OSLoaclNotificationHelper *)sharedInstance {
    static id _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [OSLoaclNotificationHelper new];
    });
    return _instance;
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

- (NSString *)notifyMessage {
    if (!_notifyMessage.length) {
        return @"下载完成了";
    }
    return _notifyMessage;
}


- (UILocalNotification *)localNotification {
    
    if (_localNotification == nil) {
        _localNotification = [UILocalNotification new];
        _localNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
        _localNotification.alertAction = nil;
        _localNotification.soundName = UILocalNotificationDefaultSoundName;
        _localNotification.alertBody = self.notifyMessage;
        _localNotification.applicationIconBadgeNumber = 1;
        _localNotification.repeatInterval = 0;
    }
    return _localNotification;
}

@end
