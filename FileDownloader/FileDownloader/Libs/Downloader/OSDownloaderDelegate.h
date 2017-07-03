//
//  OSDownloaderDelegate.h
//  FileDownloader
//
//  Created by Ossey on 2017/7/3.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloadProtocol.h"

/*
 此类遵守了OSDownloaderDelegate，作为OSDownloader的协议实现类
 主要对下载状态的更新、下载进度的更新、发送通知、下载信息的规则
 */

FOUNDATION_EXTERN NSString * const OSFileDownloadProgressChangeNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadSussessNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadFailureNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadCanceldNotification;

@interface OSDownloaderDelegate : NSObject <OSDownloaderDelegate>

@end
