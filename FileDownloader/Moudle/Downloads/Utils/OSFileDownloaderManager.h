//
//  OSFileDownloaderManager.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSFileDownloadProtocol.h"
#import "OSFileDownloader.h"
#import "OSRemoteResourceItem.h"


@interface OSFileDownloaderManager : NSObject

@property (nonatomic, class) OSFileDownloaderManager *sharedInstance;

@property (nonatomic, strong, readonly) NSMutableArray<OSRemoteResourceItem *> *downloadItems;

@property (nonatomic, strong) OSFileDownloader *downloader;

@property (nonatomic, assign) BOOL shouldAutoDownloadWhenInitialize;

@property (nonatomic, assign) NSInteger maxConcurrentDownloads;

- (void)clearAllDownloadTask;

/// 归档items
- (void)storedDownloadItems;
/// 从本地获取所有的downloadItem
- (NSMutableArray<OSRemoteResourceItem *> *)restoredDownloadItems;

- (void)start:(NSString *)url;
- (void)cancel:(NSString *)url;
- (void)pause:(NSString *)url;

/// WIFI下 下载失败时app每隔10秒下载自动下载一次全部失败的
- (void)autoDownloadFailure;
/// 暂停所有下载任务
- (void)pauseAllDownloadTask;
/// 让所有任务暂停，并进入失败状态
- (void)failureAllDownloadTask;
/// 执行下载全部任务
- (void)startAllDownloadTask;
/// 取消下载所有任务并删除临时文件
- (void)cancelAllDownloadTask;

- (NSArray<OSRemoteResourceItem *> *)downloadedItems;
- (NSArray<OSRemoteResourceItem *> *)activeDownloadItems;
- (NSArray<OSRemoteResourceItem *> *)downloadFailureItems;
- (NSArray<OSRemoteResourceItem *> *)downloadingItems;

/// 获取某种状态的任务
- (NSArray *)getDownloadItemsWithStatus:(OSFileDownloadStatus)state;
// 查找urlPath在downloadItems中对应的OSFileDownloadOperation的索引
- (NSUInteger)foundItemIndxInDownloadItemsByURL:(NSString *)urlPath;
- (BOOL)removeDownloadItemByPackageId:(NSString *)packageId;
- (void)removeAllWaitingDownloadArray;
- (void)removeFromDownloadIemsByStatus:(OSFileDownloadStatus)status;
- (void)removeActiveDownloadItems;
@end
