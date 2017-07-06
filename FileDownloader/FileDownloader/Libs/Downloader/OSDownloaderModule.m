//
//  OSDownloaderModule.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloaderModule.h"
#import "OSFileItem.h"
#import "UIApplication+ActivityIndicator.h"
#import "OSDownloaderDelegate.h"

static NSString * OSFileItemsKey = @"downloadItems";

@interface OSDownloaderModule()

@property (nonatomic, strong) OSDownloaderDelegate *downloadDelegate;
@property (nonatomic, strong) NSMutableArray<id<OSDownloadFileItemProtocol>> *downloadItems;

@end


@implementation OSDownloaderModule

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ initialize ~~~~~~~~~~~~~~~~~~~~~~~

@dynamic sharedInstance;

+ (OSDownloaderModule *)sharedInstance {
    static OSDownloaderModule *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self class] new];
    });
    return sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.downloadDelegate = [OSDownloaderDelegate new];
        self.downloader = [OSDownloader new];
        self.downloader.downloadDelegate = self.downloadDelegate;
        self.downloader.maxConcurrentDownloads = 1;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        // 本地获取
        self.downloadItems = [self restoredDownloadItems];
        [self.downloadItems enumerateObjectsUsingBlock:^(id<OSDownloadFileItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.status == OSFileDownloadStatusWaiting) {
                obj.status = OSFileDownloadStatusInterrupted;
            }
        }];
        [self storedDownloadItems];
    }
    return self;
}

- (void)setDataSource:(id<OSFileDownloaderDataSource>)dataSource {
    if (dataSource != _dataSource) {
        _dataSource = dataSource;
        
        [self _addDownloadTaskFromDataSource];
    }
}

- (void)_addDownloadTaskFromDataSource {
    if (self.dataSource
        && [self.dataSource respondsToSelector:@selector(fileDownloaderAddTasksFromRemoteURLPaths)]) {
        NSArray *urls = [self.dataSource fileDownloaderAddTasksFromRemoteURLPaths];
        
        /// 设置所有要下载的url,根据url创建OSFileItem
        [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addUrlPathToDownloadItemArray:obj];
        }];
        
        [self storedDownloadItems];
        
    }
}

/// 根据url创建或获取一个OSDownloadIem 返回
- (OSFileItem *)addUrlPathToDownloadItemArray:(NSString *)urlPath {
    @synchronized (self) {
        OSFileItem *downloadItem = nil;
        // 下载之前先去downloadItems中查找有没有相同的downloadToken，如果有就是已经添加过的
        NSInteger downloadItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (downloadItemIdx == NSNotFound) {
            // 之前没下载过
            downloadItem = [[OSFileItem alloc] initWithURL:urlPath];
            [self.downloadItems addObject:downloadItem];
        } else {
            // 之前下载过
            downloadItem = [self.downloadItems objectAtIndex:downloadItemIdx];
            if (downloadItem.status == OSFileDownloadStatusStarted) {
                BOOL isDownloading = [self.downloader isDownloadingByURL:downloadItem.urlPath];
                if (isDownloading == NO) {
                    downloadItem.status = OSFileDownloadStatusInterrupted;
                }
            }
            [self.downloadItems replaceObjectAtIndex:downloadItemIdx withObject:downloadItem];
        }
        return downloadItem;
    }
    
}



#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Public ~~~~~~~~~~~~~~~~~~~~~~~


- (void)start:(OSFileItem *)downloadItem {
    @synchronized (self) {
        if ((downloadItem.status != OSFileDownloadStatusCancelled) && (downloadItem.status != OSFileDownloadStatusSuccess)) {
            BOOL isDownloading = [self.downloader isDownloadingByURL:downloadItem.urlPath];
            if (isDownloading == NO){
                downloadItem.status = OSFileDownloadStatusStarted;
                
                // 开始下载
                if (downloadItem.resumeData.length > 0) {
                    // 从上次下载位置继续下载
                    [self.downloader downloadWithURL:downloadItem.urlPath resumeData:downloadItem.resumeData];
                    NSInteger foundIndexInDownloadItems = [self foundItemIndxInDownloadItemsByURL:downloadItem.urlPath];
                    if (foundIndexInDownloadItems == NSNotFound) {
                        [self.downloadItems addObject:downloadItem];
                    }
                } else {
                    // 从url下载新的任务
                    [self.downloader downloadWithURL:downloadItem.urlPath];
                    NSInteger foundIndexInDownloadItems = [self foundItemIndxInDownloadItemsByURL:downloadItem.urlPath];
                    if (foundIndexInDownloadItems == NSNotFound) {
                        [self.downloadItems addObject:downloadItem];
                    }
                }
                BOOL isWaiting = [self.downloader isWaitingByURL:downloadItem.urlPath];
                if (isWaiting) {
                    downloadItem.status = OSFileDownloadStatusWaiting;
                }
                // 开始下载前对所有下载的信息进行归档
                [self storedDownloadItems];
            }
        }
    }
}

- (void)cancel:(NSString *)urlPath {
    @synchronized (self) {
        /// 根据downloadIdentifier 在self.downloadItems中找到对应的item
        NSUInteger itemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (itemIdx != NSNotFound) {
            // 根据索引在self.downloadItems中取出OSFileItem，修改状态，并进行归档
            OSFileItem *downloadItem = [self.downloadItems objectAtIndex:itemIdx];
            downloadItem.status = OSFileDownloadStatusCancelled;
            if (!downloadItem.progressObj) {
                OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
                downloadItem.progressObj = progress;
            }
            if (downloadItem.progressObj.nativeProgress) {
                [downloadItem.progressObj.nativeProgress cancel];
            }
            // 将其从downloadItem中移除，并重新归档
            [self.downloadItems removeObject:downloadItem];
            [self storedDownloadItems];
            [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadCanceldNotification object:nil];
        }
        else {
            NSLog(@"ERR: Cancelled download item not found (id: %@) (%@, %d)", urlPath, [NSString stringWithUTF8String:__FILE__].lastPathComponent, __LINE__);
        }

    }
}

- (void)resume:(NSString *)urlPath {
    
    @synchronized (self) {
        NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (foundItemIdx != NSNotFound) {
            OSFileItem *downloadItem = [self.downloadItems objectAtIndex:foundItemIdx];
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
                // iOS9以上执行NSProgress 的 resume，resumingHandler会得到回调
                // OSDownloader中已经对其回调时使用了执行了恢复任务
                if (!downloadItem.progressObj) {
                    OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
                    downloadItem.progressObj = progress;
                }
                if (downloadItem.progressObj.nativeProgress) {
                    [downloadItem.progressObj.nativeProgress resume];
                    
                    BOOL isWaiting = [self.downloader isWaitingByURL:downloadItem.urlPath];
                    if (isWaiting) {
                        downloadItem.status = OSFileDownloadStatusWaiting;
                    }

                } else {
                    [self start:downloadItem];
                }
            } else {
                [self start:downloadItem];
            }
        } else {
            id<OSDownloadFileItemProtocol> item = [self addUrlPathToDownloadItemArray:urlPath];
            [self start:item];
        }
        [self storedDownloadItems];
    }
    
}

- (void)pause:(NSString *)urlPath {
    
    @synchronized (self) {
        NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (foundItemIdx != NSNotFound) {
            OSFileItem *downloadItem = [self.downloadItems objectAtIndex:foundItemIdx];
            BOOL isDownloading = [self.downloader isDownloadingByURL:downloadItem.urlPath];
            if (isDownloading) {
                downloadItem.status = OSFileDownloadStatusPaused;
                if (!downloadItem.progressObj) {
                    OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
                    downloadItem.progressObj = progress;
                }
                if (downloadItem.progressObj.nativeProgress) {
                    [downloadItem.progressObj.nativeProgress pause];
                }
                // 暂停前前对所有下载的信息进行归档
                [self storedDownloadItems];
            }
        }
    }
}

- (void)clearAllDownloadTask {
    [self.downloadItems removeAllObjects];
    [self storedDownloadItems];
}

- (NSArray<OSFileItem *> *)getAllSuccessItems {
    if (!self.downloadItems.count) {
        return nil;
    }
    
    NSMutableArray *allSuccessItems = [NSMutableArray array];
    [self.downloadItems enumerateObjectsUsingBlock:^(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.status == OSFileDownloadStatusSuccess) {
            [allSuccessItems addObject:obj];
        }
    }];
    return allSuccessItems;
}

- (NSArray<OSFileItem *> *)getActiveDownloadItems {
    if (!self.downloadItems.count) {
        return nil;
    }
    
    NSMutableArray *downloadingItems = [NSMutableArray array];
    [self.downloadItems enumerateObjectsUsingBlock:^(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.status != OSFileDownloadStatusSuccess) {
            [downloadingItems addObject:obj];
        }
    }];
    return downloadingItems;
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark - 下载信息存储
////////////////////////////////////////////////////////////////////////


/// 从本地获取所有的downloadItem
- (NSMutableArray<OSFileItem *> *)restoredDownloadItems {
    
    NSMutableArray<OSFileItem *> *restoredDownloadItems = [NSMutableArray array];
    NSMutableArray<NSData *> *restoredMutableDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileItemsKey];
    if (!restoredMutableDataArray) {
        restoredMutableDataArray = [NSMutableArray array];
    }
    
    [restoredMutableDataArray enumerateObjectsUsingBlock:^(NSData * _Nonnull data, NSUInteger idx, BOOL * _Nonnull stop) {
        OSFileItem *item = nil;
        if (data) {
            @try {
                // 解档
                item = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                if (item.resumeData.length) {
                    NSLog(@"---");
                }
            } @catch (NSException *exception) {
                @throw exception;
            } @finally {
                
            }
            if (item) {
                [restoredDownloadItems addObject:item];
            }
        }
        
    }];
    
    return restoredDownloadItems;
}

/// 归档items
- (void)storedDownloadItems {
    
    NSMutableArray<NSData *> *downloadItemsArchiveArray = [NSMutableArray arrayWithCapacity:self.downloadItems.count];
    
    [self.downloadItems enumerateObjectsUsingBlock:^(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSData *itemData = nil;
        @try {
            itemData = [NSKeyedArchiver archivedDataWithRootObject:obj];
        } @catch (NSException *exception) {
            @throw exception;
        } @finally {
            
        }
        if (itemData) {
            [downloadItemsArchiveArray addObject:itemData];
        }
        
    }];
    
    [[NSUserDefaults standardUserDefaults] setObject:downloadItemsArchiveArray forKey:OSFileItemsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Notify
////////////////////////////////////////////////////////////////////////

- (void)applicationWillTerminate {
    [self storedDownloadItems];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

// 查找数组中第一个符合条件的对象（代码块过滤），返回对应索引
// 查找urlPath在downloadItems中对应的OSDownloadItem的索引
- (NSUInteger)foundItemIndxInDownloadItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    return [self.downloadItems indexOfObjectPassingTest:^BOOL(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        return [urlPath isEqualToString:obj.urlPath];
    }];
}



@end
