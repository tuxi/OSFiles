//
//  OSLoaclNotificationHelper.h
//  OSFileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSLoaclNotificationHelper : NSObject

@property (nonatomic, strong, class) OSLoaclNotificationHelper *sharedInstance;

/// 通知的内容
@property (nonatomic, strong) NSString *notifyMessage;
/// 注册本地通知
- (void)registerLocalNotificationWithBlock:(void (^)(UILocalNotification *))block;
/// 发送本地通知
- (void)sendLocalNotificationWithMessage:(NSString *)message;

@end
