//
//  OSDownloaderModule.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloadProtocol.h"
#import "OSDownloader.h"

@protocol OSFileDownloaderDataSource <NSObject>

@optional
/// 需要下载的任务, 默认按照url在数组中的索引顺序下载
/// @return 所有需要下载的url 字符串
- (NSArray<NSString *> *)fileDownloaderAddTasksFromRemoteURLPaths;

@end


@class OSFileItem;

@interface OSDownloaderModule : NSObject

@property (nonatomic, class) OSDownloaderModule *sharedInstance;

@property (nonatomic, strong, readonly) NSMutableArray *downloadItems;

@property (nonatomic, weak) id<OSFileDownloaderDataSource> dataSource;

@property (nonatomic, strong) OSDownloader *downloader;

@property (nonatomic, assign) BOOL shouldAutoDownloadWhenInitialize;

- (void)clearAllDownloadTask;

/// 归档items
- (void)storedDownloadItems;
/// 从本地获取所有的downloadItem
- (NSMutableArray *)restoredDownloadItems;

- (void)start:(NSString *)url;
- (void)cancel:(NSString *)url;
- (void)resume:(NSString *)url;
- (void)pause:(NSString *)url;

- (NSArray *)getAllSuccessItems;
- (NSArray *)getActiveDownloadItems;
/// 所有展示中的文件，还未开始下载时存放的，当文件取消下载时也会存放到此数组
- (NSMutableArray *)displayItems;
@end
