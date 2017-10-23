//
//  OSFileDownloaderManager.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileDownloaderManager.h"
#import "UIApplication+ActivityIndicator.h"
#import "OSFileDownloaderDelegate.h"
#import "OSFileDownloadConst.h"

static NSString * const OSFileDownloadOperationsKey = @"downloadItems";
static NSString * const AutoDownloadWhenInitializeKey = @"AutoDownloadWhenInitialize";

@interface OSFileDownloaderManager()

@property (nonatomic, strong) OSFileDownloaderDelegate *downloadDelegate;
/// 所有添加到下载中的热任务，包括除了未开始和成功状态的所有下载任务
@property (nonatomic, strong) NSMutableArray *downloadItems;
/// 所有展示中的文件，还未开始下载时存放的，当文件取消下载时也会存放到此数组
@property (nonatomic, strong) NSMutableArray *displayItems;

@end


@implementation OSFileDownloaderManager

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

@dynamic sharedInstance;
@synthesize shouldAutoDownloadWhenInitialize = _shouldAutoDownloadWhenInitialize;


+ (OSFileDownloaderManager *)sharedInstance {
    static OSFileDownloaderManager *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [OSFileDownloaderManager new];
    });
    return _sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _displayItems = [NSMutableArray array];
        self.downloadDelegate = [OSFileDownloaderDelegate new];
        self.downloader = [OSFileDownloader new];
        self.downloader.downloadDelegate = self.downloadDelegate;
        self.downloader.maxConcurrentDownloads = 3;
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
                                obj.status == OSFileDownloadStatusWaiting |
                                obj.status == OSFileDownloadStatusFailure;
                            }];
    NSArray *needDownloads = [self.downloadItems objectsAtIndexes:indexSet];
    if (self.shouldAutoDownloadWhenInitialize) {
        needDownloads = [needDownloads sortedArrayUsingComparator:^NSComparisonResult(OSFileItem *  _Nonnull obj1, OSFileItem *  _Nonnull obj2) {
            NSComparisonResult result = [@(obj1.status) compare:@(obj2.status)];
            return result == NSOrderedDescending;
        }];
        
        [needDownloads enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self start:obj.urlPath];
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
        && [self.dataSource respondsToSelector:@selector(OSFileDownloaderAddTasksFromRemoteURLPaths)]) {
        NSArray *urls = [self.dataSource OSFileDownloaderAddTasksFromRemoteURLPaths];
        [self.displayItems removeAllObjects];
        [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addUrlPathToDisplayItemArray:obj downloadItem:nil];
        }];
        
    }
}

/// 根据url创建或获取一个OSFileDownloadIem 返回
- (BOOL)addUrlPathToDisplayItemArray:(NSString *)urlPath downloadItem:(OSFileItem * *)downloadItem {
    @synchronized (self) {
        OSFileItem *item = nil;
        // 下载任务中没有
        NSUInteger downloadItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        // 显示的队列中也没有
        NSUInteger displayItemIdx = [self foundItemIndxInDisplayItemsByURL:urlPath];
        if (downloadItemIdx == NSNotFound && displayItemIdx == NSNotFound) {
            item = [[OSFileItem alloc] init];
            item.urlPath = urlPath;
            item.fileName = urlPath.lastPathComponent;
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
    
    NSAssert(urlPath, @"urlPath is not nil");
    
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
                OSFileItem * item = [[OSFileItem alloc] init];
                item.urlPath = urlPath;
                item.fileName = urlPath.lastPathComponent;
                [self.downloadItems addObject:item];
                [self start:urlPath];
            }
        } else {
            OSFileItem * item = [self.downloadItems objectAtIndex:foundIndexInDownloadItems];
            if (item.status != OSFileDownloadStatusSuccess) {
                BOOL isDownloading = [self.downloader isDownloading:item.urlPath];
                if (isDownloading == NO){
                    item.status = OSFileDownloadStatusDownloading;
                   id<OSFileDownloadOperation> opeation = [self.downloader downloadTaskWithURLPath:urlPath localPath:item.localPath progress:^(NSProgress * _Nonnull progress) {
                        
                    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable localURL, NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"%@", error);
                        } else {
                            NSLog(@"%@ 任务下载完成", localURL);
                        }
                    }];
                    BOOL isWaiting = [self.downloader isWaiting:opeation.urlPath];
                    if (isWaiting) {
                        item.status = OSFileDownloadStatusWaiting;
                    }
                    [self storedDownloadItems];
                }
            }
        }
        
    }
}

- (void)addDownloadItemByUrlPath:(NSString *)urlPath {
    NSAssert(urlPath, @"urlPath is not nil");
    NSUInteger foundIdxInDispaly = [self foundItemIndxInDisplayItemsByURL:urlPath];
    if (foundIdxInDispaly != NSNotFound) {
        [self.displayItems removeObjectAtIndex:foundIdxInDispaly];
    }
}

- (void)cancel:(NSString *)urlPath {
    NSAssert(urlPath, @"urlPath is not nil");
    @synchronized (_downloadItems) {
        /// 根据downloadIdentifier 在self.downloadItems中找到对应的item
        NSUInteger itemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (itemIdx != NSNotFound) {
            // 根据索引在self.downloadItems中取出OSFileDownloadOperation，修改状态，并进行归档
            OSFileItem *item = [self.downloadItems objectAtIndex:itemIdx];
            item.status = OSFileDownloadStatusNotStarted;
            id<OSFileDownloadOperation> operation = [self.downloader getDownloadOperationByURL:urlPath];
            if (operation.progressObj.nativeProgress) {
                [operation cancel];
            } else {
                [self.downloader cancelWithURL:urlPath];
            }
            // 将其从downloadItem中移除，并添加到display中 重新归档
            NSUInteger founIdxInDisplay = [self foundItemIndxInDisplayItemsByURL:urlPath];
            [self deleteFile:item.localPath];
            [self.downloadItems removeObject:item];
            item.urlPath = urlPath;
            item.fileName = urlPath.lastPathComponent;
            if (founIdxInDisplay == NSNotFound) {
                [self.displayItems addObject:item];
            } else {
                [self.displayItems replaceObjectAtIndex:founIdxInDisplay withObject:item];
            }
            [self storedDownloadItems];
            [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadCanceldNotification object:nil];
        }
        else {
            DLog(@"ERR: Cancelled download item not found (id: %@)", urlPath);
        }
        
    }
}


- (void)pause:(NSString *)urlPath {
    NSAssert(urlPath, @"urlPath is not nil");
    @synchronized (self) {
        NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:urlPath];
        if (foundItemIdx != NSNotFound) {
            OSFileItem *item = [self.downloadItems objectAtIndex:foundItemIdx];
            BOOL isDownloading = [self.downloader isDownloading:urlPath];
            id<OSFileDownloadOperation> operation = [self.downloader getDownloadOperationByURL:urlPath];
            if (isDownloading) {
                item.status = OSFileDownloadStatusPaused;
                if (operation.progressObj.nativeProgress) {
                    [operation pause];
                }
            } else {
                BOOL isWaiting = [self.downloader isWaiting:urlPath];
                if (isWaiting) {
                    if (operation.progressObj.nativeProgress) {
                        [operation pause];
                    } else {
                        [self.downloader pauseWithURL:urlPath];
                    }
                    item.status = OSFileDownloadStatusPaused;
                } else {
                    // 不在下载队列中，也不在等待队列中，就标记为取消
                    item.status = OSFileDownloadStatusFailure;
                }
            }
            [self storedDownloadItems];
        }
    }
}

- (BOOL)deleteFile:(NSString *)localPath {
    NSAssert(localPath, @"localPath is not nil");
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

- (void)clearAllDownloadTask {
    @synchronized (_downloadItems) {
        typeof(self) weakSelf = self;
        [self.downloadItems enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.status == OSFileDownloadStatusDownloading || obj.status == OSFileDownloadStatusWaiting) {
                [self cancel:obj.urlPath];
            }
            [weakSelf deleteFile:obj.localPath];
        }];
        [self.downloadItems removeAllObjects];
        [self storedDownloadItems];
        [self _addDownloadTaskFromDataSource];
    }
    
}

- (NSArray<OSFileItem *> *)downloadedItems {
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

- (NSArray<OSFileItem *> *)activeDownloadItems {
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
    NSMutableArray<NSData *> *restoredMutableDataArray = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileDownloadOperationsKey];
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
    
    [[NSUserDefaults standardUserDefaults] setObject:downloadItemsArchiveArray forKey:OSFileDownloadOperationsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Notify
////////////////////////////////////////////////////////////////////////

- (void)applicationWillTerminate {
    if (!self.shouldAutoDownloadWhenInitialize) {
        [[self activeDownloadItems] enumerateObjectsUsingBlock:^(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self pause:obj.urlPath];
        }];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

// 查找urlPath在displayItems中对应的OSFileDownloadOperation的索引
- (NSUInteger)foundItemIndxInDisplayItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    return [self.displayItems indexOfObjectPassingTest:
            ^BOOL(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [urlPath isEqualToString:obj.urlPath];
            }];
}


// 查找urlPath在downloadItems中对应的OSFileDownloadOperation的索引
- (NSUInteger)foundItemIndxInDownloadItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    return [self.downloadItems indexOfObjectPassingTest:
            ^BOOL(OSFileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [urlPath isEqualToString:obj.urlPath];
            }];
}


- (BOOL)removeDownloadItemByPackageId:(NSString *)packageId {
    if (!packageId.length || !self.downloadItems.count) {
        return NO;
    }
    @synchronized (_downloadItems) {
        NSIndexSet *indexSet = [self.downloadItems indexesOfObjectsPassingTest:^BOOL(OSFileItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.fileName isEqualToString:packageId];
        }];
        if (!indexSet.count) {
            return NO;
        }
        
        [_downloadItems removeObjectsAtIndexes:indexSet];
        
        return YES;
    }
}
@end
