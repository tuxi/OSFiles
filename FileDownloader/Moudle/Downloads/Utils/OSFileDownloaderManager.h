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
#import "OSFileItem.h"

@protocol OSFileDownloaderDataSource <NSObject>

@optional
/// 需要下载的任务, 默认按照url在数组中的索引顺序下载
/// @return 所有需要下载的url 字符串
- (NSArray<NSString *> *)OSFileDownloaderAddTasksFromRemoteURLPaths;

@end


@interface OSFileDownloaderManager : NSObject

@property (nonatomic, class) OSFileDownloaderManager *sharedInstance;

@property (nonatomic, strong, readonly) NSMutableArray<OSFileItem *> *downloadItems;

@property (nonatomic, weak) id<OSFileDownloaderDataSource> dataSource;

@property (nonatomic, strong) OSFileDownloader *downloader;

@property (nonatomic, assign) BOOL shouldAutoDownloadWhenInitialize;

@property (nonatomic, assign) NSInteger maxConcurrentDownloads;

- (void)clearAllDownloadTask;

/// 归档items
- (void)storedDownloadItems;
/// 从本地获取所有的downloadItem
- (NSMutableArray<OSFileItem *> *)restoredDownloadItems;

- (void)start:(NSString *)url;
- (void)cancel:(NSString *)url;
- (void)pause:(NSString *)url;

/// 下载失败时app每隔10秒下载自动下载一次全部失败的
- (void)autoDownloadFailure;

- (NSArray<OSFileItem *> *)downloadedItems;
- (NSArray<OSFileItem *> *)activeDownloadItems;
- (NSArray<OSFileItem *> *)downloadFailureItems;
/// 所有展示中的文件，还未开始下载时存放的，当文件取消下载时也会存放到此数组
- (NSMutableArray<OSFileItem *> *)displayItems;
/// 获取某种状态的任务
- (NSArray *)getDownloadItemsWithStatus:(OSFileDownloadStatus)state;

- (BOOL)removeDownloadItemByPackageId:(NSString *)packageId;
@end
