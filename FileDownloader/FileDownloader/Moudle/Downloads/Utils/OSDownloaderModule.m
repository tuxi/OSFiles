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
#import "OSDownloadConst.h"

static NSString * const OSFileItemsKey = @"downloadItems";
static NSString * const AutoDownloadWhenInitializeKey = @"AutoDownloadWhenInitialize";

@interface OSDownloaderModule()

@property (nonatomic, strong) OSDownloaderDelegate *downloadDelegate;
/// 所有添加到下载中的热任务，包括除了未开始和成功状态的所有下载任务
@property (nonatomic, strong) NSMutableArray *downloadItems;
/// 所有展示中的文件，还未开始下载时存放的，当文件取消下载时也会存放到此数组
@property (nonatomic, strong) NSMutableArray *displayItems;

@end


@implementation OSDownloaderModule

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

@dynamic sharedInstance;
@synthesize shouldAutoDownloadWhenInitialize = _shouldAutoDownloadWhenInitialize;


+ (OSDownloaderModule *)sharedInstance {
    static OSDownloaderModule *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [OSDownloaderModule new];
    });
    return _sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _displayItems = [NSMutableArray array];
        self.downloadDelegate = [OSDownloaderDelegate new];
        self.downloader = [OSDownloader new];
        self.downloader.downloadDelegate = self.downloadDelegate;
        self.downloader.maxConcurrentDownloads = 1;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        self.downloadItems = [self restoredDownloadItems];
    }
    return self;
}

- (void)setShouldAutoDownloadWhenInitialize:(BOOL)shouldAutoDownloadWhenInitialize {
    _shouldAutoDownloadWhenInitialize = shouldAutoDownloadWhenInitialize;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initDownloadTasks];
    });
    [[NSUserDefaults standardUserDefaults] setBool:shouldAutoDownloadWhenInitialize
                                            forKey:AutoDownloadWhenInitializeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

- (BOOL)shouldAutoDownloadWhenInitialize {
    return [[NSUserDefaults standardUserDefaults] boolForKey:AutoDownloadWhenInitializeKey];
}

- (void)initDownloadTasks {
    NSIndexSet *indexSet = [self.downloadItems indexesOfObjectsPassingTest:
                            ^BOOL(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                return
                                obj.status == OSFileDownloadStatusDownloading |
                                obj.status == OSFileDownloadStatusWaiting;
                            }];
    NSArray *needDownloads = [self.downloadItems objectsAtIndexes:indexSet];
    if (self.shouldAutoDownloadWhenInitialize) {
        needDownloads = [needDownloads sortedArrayUsingComparator:^NSComparisonResult(OSFileItem *  _Nonnull obj1, OSFileItem *  _Nonnull obj2) {
            NSComparisonResult result = [@(obj1.status) compare:@(obj2.status)];
            return result == NSOrderedDescending;
        }];
        
        [needDownloads enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self resume:obj.urlPath];
        }];
    } else {
        [needDownloads enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.status = OSFileDownloadStatusPaused;
        }];
    }
    [self storedDownloadItems];
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
        [self.displayItems removeAllObjects];
        [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addUrlPathToDisplayItemArray:obj downloadItem:nil];
        }];
        
    }
}

/// 根据url创建或获取一个OSDownloadIem 返回
- (BOOL)addUrlPathToDisplayItemArray:(NSString *)urlPath downloadItem:(OSFileItem * *)downloadItem {
    @synchronized (self) {
        OSFileItem *item = nil;
        // 下载任务中没有
        NSUInteger downloadItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        // 显示的队列中也没有
        NSUInteger displayItemIdx = [self foundItemIndxInDisplayItemsByURL:urlPath];
        if (downloadItemIdx == NSNotFound && displayItemIdx == NSNotFound) {
            item = [[OSFileItem alloc] initWithURL:urlPath];
            [self.displayItems addObject:item];
            if (downloadItem) {
                *downloadItem = item;
            }
            return YES;
        }
        if (displayItemIdx != NSNotFound) {
            if (downloadItem) {
                item = [self.displayItems objectAtIndex:displayItemIdx];
                *downloadItem = item;
            }
            return YES;
        }
        return NO;
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////


- (void)start:(NSString *)urlPath {
    @synchronized (_downloadItems) {
        
        NSUInteger foundIndexInDownloadItems = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (foundIndexInDownloadItems == NSNotFound) {
            NSUInteger foundIndexInDisplay = [self foundItemIndxInDisplayItemsByURL:urlPath];
            if (foundIndexInDisplay != NSNotFound) {
                OSFileItem * item = [self.displayItems objectAtIndex:foundIndexInDisplay];
                item.status = OSFileDownloadStatusNotStarted;
                [self.downloadItems addObject:item];
                [self.displayItems removeObjectAtIndex:foundIndexInDisplay];
                [self start:urlPath];
            } else {
                OSFileItem * item = [[OSFileItem alloc] initWithURL:urlPath];
                [self.downloadItems addObject:item];
                [self start:urlPath];
            }
        } else {
            OSFileItem * downloadItem = [self.downloadItems objectAtIndex:foundIndexInDownloadItems];
            if (downloadItem.status != OSFileDownloadStatusSuccess) {
                BOOL isDownloading = [self.downloader isDownloading:downloadItem.urlPath];
                if (isDownloading == NO){
                    downloadItem.status = OSFileDownloadStatusDownloading;
                    [self.downloader downloadTaskWithURLPath:downloadItem.urlPath progress:nil completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"%@", error);
                        } else {
                            NSLog(@"%@ 任务下载完成", filePath);
                        }
                    }];
                    BOOL isWaiting = [self.downloader isWaiting:downloadItem.urlPath];
                    if (isWaiting) {
                        downloadItem.status = OSFileDownloadStatusWaiting;
                    }
                    [self storedDownloadItems];
                }
            }
        }
        
    }
}

- (void)addDownloadItemByUrlPath:(NSString *)urlPath {
    NSUInteger foundIdxInDispaly = [self foundItemIndxInDisplayItemsByURL:urlPath];
    if (foundIdxInDispaly != NSNotFound) {
        [self.displayItems removeObjectAtIndex:foundIdxInDispaly];
    }
}

- (void)cancel:(NSString *)urlPath {
    @synchronized (_downloadItems) {
        /// 根据downloadIdentifier 在self.downloadItems中找到对应的item
        NSUInteger itemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (itemIdx != NSNotFound) {
            // 根据索引在self.downloadItems中取出OSFileItem，修改状态，并进行归档
            OSFileItem *downloadItem = [self.downloadItems objectAtIndex:itemIdx];
            downloadItem.status = OSFileDownloadStatusNotStarted;
            if (!downloadItem.progressObj) {
                OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
                downloadItem.progressObj = progress;
            }
            if (downloadItem.progressObj.nativeProgress) {
                [downloadItem.progressObj.nativeProgress cancel];
            } else {
                [self.downloader cancelWithURL:urlPath];
            }
            // 将其从downloadItem中移除，并添加到display中 重新归档
            NSUInteger founIdxInDisplay = [self foundItemIndxInDisplayItemsByURL:urlPath];
            [self deleteFile:downloadItem.localURL.path];
            [self.downloadItems removeObject:downloadItem];
            OSFileItem *cancelItem = [[OSFileItem alloc] initWithURL:urlPath];
            cancelItem.status = OSFileDownloadStatusNotStarted;
            if (founIdxInDisplay == NSNotFound) {
                [self.displayItems addObject:cancelItem];
            } else {
                [self.displayItems replaceObjectAtIndex:founIdxInDisplay withObject:cancelItem];
            }
            [self storedDownloadItems];
            [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadCanceldNotification object:nil];
        }
        else {
            DLog(@"ERR: Cancelled download item not found (id: %@)", urlPath);
        }
        
    }
}

- (void)resume:(NSString *)urlPath {
    
    @synchronized (_downloadItems) {
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
                    [downloadItem resume];
                    
                    BOOL isWaiting = [self.downloader isWaiting:downloadItem.urlPath];
                    if (isWaiting) {
                        downloadItem.status = OSFileDownloadStatusWaiting;
                    }
                    
                } else {
                    [self start:urlPath];
                }
            } else {
                [self start:urlPath];
            }
        } else {
            [self start:urlPath];
        }
        [self storedDownloadItems];
    }
    
}

- (void)pause:(NSString *)urlPath {
    
    @synchronized (self) {
        NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (foundItemIdx != NSNotFound) {
            OSFileItem *downloadItem = [self.downloadItems objectAtIndex:foundItemIdx];
            BOOL isDownloading = [self.downloader isDownloading:downloadItem.urlPath];
            if (isDownloading) {
                downloadItem.status = OSFileDownloadStatusPaused;
                if (!downloadItem.progressObj) {
                    OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
                    downloadItem.progressObj = progress;
                }
                if (downloadItem.progressObj.nativeProgress) {
                    [downloadItem pause];
                }
            } else {
                BOOL isWaiting = [self.downloader isWaiting:urlPath];
                if (isWaiting) {
                    OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
                    if (progress.nativeProgress) {
                        [progress.nativeProgress pause];
                        downloadItem.progressObj = progress;
                    } else {
                        [self.downloader pauseWithURL:urlPath];
                    }
                    downloadItem.status = OSFileDownloadStatusPaused;
                } else {
                    // 不在下载队列中，也不在等待队列中，就标记为取消
                    downloadItem.status = OSFileDownloadStatusFailure;
                }
            }
            [self storedDownloadItems];
        }
    }
}

- (BOOL)deleteFile:(NSString *)localPath {
    @synchronized (_downloadItems) {
        NSError *error = nil;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:localPath];
        if (isExist) {
            BOOL isRemoveSuccess = [[NSFileManager defaultManager] removeItemAtPath:localPath error:&error];
            if (isRemoveSuccess) {
                DLog(@"remove localFile success");
                return YES;
            }
        }
        return NO;
    }
}

- (void)clearAllDownloadTask {
    @synchronized (_downloadItems) {
        typeof(self) weakSelf = self;
        [self.downloadItems enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.status == OSFileDownloadStatusDownloading) {
                [self cancel:obj.urlPath];
            }
            [weakSelf deleteFile:obj.localURL.path];
        }];
        [self.downloadItems removeAllObjects];
        [self storedDownloadItems];
        [self _addDownloadTaskFromDataSource];
    }
    
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
        return @[];
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
    if (!self.shouldAutoDownloadWhenInitialize) {
        [[self getActiveDownloadItems] enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self pause:obj.urlPath];
        }];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

// 查找urlPath在displayItems中对应的OSDownloadOperation的索引
- (NSUInteger)foundItemIndxInDisplayItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    return [self.displayItems indexOfObjectPassingTest:
            ^BOOL(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [urlPath isEqualToString:obj.urlPath];
            }];
}


// 查找urlPath在downloadItems中对应的OSDownloadOperation的索引
- (NSUInteger)foundItemIndxInDownloadItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    return [self.downloadItems indexOfObjectPassingTest:
            ^BOOL(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [urlPath isEqualToString:obj.urlPath];
            }];
}



@end
