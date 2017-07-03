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
- (NSArray<NSString *> *)addDownloadTaskFromRemoteURLs;

@end


@class OSFileItem;

@interface OSDownloaderModule : NSObject <OSDownloadOperationProtocol>

@property (nonatomic, class) OSDownloaderModule *sharedInstance;

@property (nonatomic, strong, readonly) NSMutableArray<id<OSDownloadFileItemProtocol>> *downloadItems;

@property (nonatomic, weak) id<OSFileDownloaderDataSource> dataSource;

@property (nonatomic, strong) OSDownloader *downloader;

- (void)clearAllDownloadTask;

/// 归档items
- (void)storedDownloadItems;
/// 从本地获取所有的downloadItem
- (NSMutableArray<id<OSDownloadFileItemProtocol>> *)restoredDownloadItems;
@end
