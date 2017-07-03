//
//  OSFileDownloadModule.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloadProtocol.h"

@class OSDownloaderManager;


@protocol OSFileDownloaderDataSource <NSObject>

@optional
/// 需要下载的任务, 默认按照url在数组中的索引顺序下载
/// @return 所有需要下载的url 字符串
- (NSArray<NSString *> *)addDownloadTaskFromRemoteURLs;

@end


/*
 此类遵守了OSDownloadProtocol，作为OSDownloaderManager的协议实现类
 主要对下载状态的更新、下载进度的更新、发送通知、下载信息的规则
 */

FOUNDATION_EXTERN NSString * const OSFileDownloadProgressChangeNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadSussessNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadFailureNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadCanceldNotification;

@class OSFileItem;

@interface OSFileDownloadModule : NSObject <OSDownloadProtocol>

@property (nonatomic, strong, readonly) NSMutableArray<OSFileItem *> *downloadItems;

@property (nonatomic, weak) id<OSFileDownloaderDataSource> dataSource;

- (void)clearAllDownloadTask;


@end
