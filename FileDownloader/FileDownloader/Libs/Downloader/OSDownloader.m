//
//  OSDownloader.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloader.h"
#import "OSDownloadItem.h"
#import "NSURLSession+CorrectedResumeData.h"

// 后台任务的标识符
#define kBackgroundDownloadSessionIdentifier [NSString stringWithFormat:@"%@.OSDownloader", [NSBundle mainBundle].bundleIdentifier]

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#define OSPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


static NSString * const OSDownloadURLKey = @"downloadURLPath";
static NSString * const OSDownloadResumeDataKey = @"resumeData";

NSString * const OSDownloaderFolderNameKey = @"OSDownloaderFolder";

// 下载速度key
static NSString * const OSDownloadBytesPerSecondSpeedKey = @"bytesPerSecondSpeed";
// 剩余时间key
static NSString * const OSDownloadRemainingTimeKey = @"remainingTime";

@interface OSDownloader () <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *backgroundSeesion;
/// 下载的任务(包括正在下载的、暂停的) key 为 taskIdentifier， value 为 OSDownloadItem, 下载完成后会从此集合中移除
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, OSDownloadItem *> *activeDownloadsDictionary;
/// 等待下载的任务数组 每个元素 字典 为一个等待的任务
@property (nonatomic, strong) NSMutableArray<NSDictionary <NSString *, NSObject *> *> *waitingDownloadArray;
@property (nonatomic, copy) OSBackgroundSessionCompletionHandler backgroundSessionCompletionHandler;
@property (nonatomic, strong) NSOperationQueue *backgroundSeesionQueue;
@property (nonatomic, strong) NSURL *downloaderFolderPath;
@property (nonatomic, strong) dispatch_semaphore_t lockSemaphore;


@end

@implementation OSDownloader

@synthesize maxConcurrentDownloads = _maxConcurrentDownloads;

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lockSemaphore = dispatch_semaphore_create(1);

    }
    return self;
}





- (NSURLSession *)backgroundSeesion {
    if (!_backgroundSeesion) {
        _backgroundSeesion = [NSURLSession sessionWithConfiguration:[self _createBackgroundSessionConfig] delegate:self delegateQueue:self.backgroundSeesionQueue];
        _backgroundSeesion.sessionDescription = @"OSDownload_BackgroundSession";
    }
    return _backgroundSeesion;
}


- (NSArray<NSURLSessionDownloadTask *> *)downloadTasks {
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.backgroundSeesion getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        tasks = downloadTasks;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tasks;
}

- (void)getDownloadTasks:(void (^)(NSArray *downloadTasks))downloadTasksBlock {
    [self.backgroundSeesion getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if (downloadTasksBlock) {
            downloadTasksBlock(downloadTasks);
        }
    }];
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Download
////////////////////////////////////////////////////////////////////////

- (void)downloadWithURL:(NSString *)urlPath {
    [self downloadWithURL:urlPath resumeData:nil];
}


- (void)downloadWithURL:(NSString *)urlPath resumeData:(NSData *)resumeData {
     __weak typeof(self) weakSelf = self;
    dispatch_block_t downloadBlock = ^{
        NSUInteger taskIdentifier = 0;
        NSURL *remoteURL = [NSURL URLWithString:urlPath];
        BOOL isValidResumeData = [weakSelf __isValidResumeData:resumeData];
        // 当前同时下载的数量是否超出最大的设定
        if (weakSelf.maxConcurrentDownloads == -1 || weakSelf.activeDownloadsDictionary.count < weakSelf.maxConcurrentDownloads) {
            
            NSURLSessionDownloadTask *sessionDownloadTask = nil;
            OSDownloadItem *downloadItem = nil;
            NSProgress *naviteProgress = [weakSelf _createNativeProgress];
            naviteProgress.totalUnitCount++;
            [naviteProgress becomeCurrentWithPendingUnitCount:1];
            if (isValidResumeData) {
                // 当之前下载过，就按照之前的进度继续下载
                if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_4) {
                    // NSURLSession在iOS10上的Bug 在iOS10上，resumeData不能直接使用, 使用处理后的
                    sessionDownloadTask = [weakSelf.backgroundSeesion downloadTaskWithCorrectResumeData:resumeData];
                } else {
                    sessionDownloadTask = [weakSelf.backgroundSeesion downloadTaskWithResumeData:resumeData];
                }
            } else if (remoteURL) {
                // 之前未下载过，就开启新的任务
                sessionDownloadTask = [weakSelf.backgroundSeesion downloadTaskWithURL:remoteURL];
            }
            taskIdentifier = sessionDownloadTask.taskIdentifier;
            sessionDownloadTask.taskDescription = urlPath;
            downloadItem = [[OSDownloadItem alloc] initWithURL:urlPath
                                           sessionDownloadTask:sessionDownloadTask];
            if (isValidResumeData) {
                downloadItem.resumedFileSizeInBytes = [resumeData length];
                downloadItem.downloadStartDate = [NSDate date];
                downloadItem.bytesPerSecondSpeed = 0;
            }
            [naviteProgress resignCurrent];
            [weakSelf _downloadTaskCallBack:sessionDownloadTask downloadItem:downloadItem];
            [sessionDownloadTask resume];
        } else {
            
            // 超出同时的最大下载数量时，将新的任务的aResumeData或者aRemoteURL添加到等待下载数组中
            NSMutableDictionary *waitingDownloadDict = [NSMutableDictionary dictionary];
            if (urlPath) {
                [waitingDownloadDict setObject:urlPath forKey:OSDownloadURLKey];
            }
            if (resumeData) {
                [waitingDownloadDict setObject:resumeData forKey:OSDownloadResumeDataKey];
            }
            [weakSelf.waitingDownloadArray addObject:waitingDownloadDict];
            [weakSelf _didWaitingDownloadForUrlPath:urlPath];
        }

    };
    
    /// 通过getTasksWithCompletionHandler 获取到的sessionDownloadTask去恢复下载，这样系统可以解决比如app突然重启时resumeData未保存起来，再次启动app时无remuseData而断点续传的问题
    __unused void (^downloadWithgetTask)(NSURLSessionDownloadTask *) = ^(NSURLSessionDownloadTask *sessionDownloadTask){
        NSString *urlPath = [[sessionDownloadTask taskDescription] copy];
        if (urlPath) {
            NSProgress *rootProgress = [weakSelf _createNativeProgress];
            rootProgress.totalUnitCount++;
            // UnitCount是一个基于UI上的完整任务的单元数
            // 将此rootProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
            [rootProgress becomeCurrentWithPendingUnitCount:1];
            
            OSDownloadItem *downloadItem = [[OSDownloadItem alloc] initWithURL:urlPath
                                                           sessionDownloadTask:sessionDownloadTask];
            // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用
            [rootProgress resignCurrent];
            
            [self _downloadTaskCallBack:sessionDownloadTask downloadItem:downloadItem];
            [sessionDownloadTask resume];
        }
        
    };
    
    
    [self getDownloadTasks:^(NSArray *downloadTasks) {
        NSUInteger foundIndexInDownloadTasks =
        [downloadTasks indexOfObjectPassingTest:
         ^BOOL(NSURLSessionDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
             return [obj.taskDescription isEqualToString:urlPath];
         }];
        if (foundIndexInDownloadTasks != NSNotFound) {
            NSURLSessionDownloadTask *sessionDownloadTask =
            [self.downloadTasks objectAtIndex:foundIndexInDownloadTasks];
            downloadWithgetTask(sessionDownloadTask);
        } else {
            downloadBlock();
        }
    }];
    
    
}



/// 通过urlPath恢复下载
- (void)resumeWithURL:(NSString *)urlPath {
    
    // 判断文件是否在下载中
    BOOL isDownloading = [self isDownloadingByURL:urlPath];
    // 如果不在下载中，就执行恢复
    if (!isDownloading) {
        if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(resumeDownloadWithURL:)]) {
            [self.downloadDelegate resumeDownloadWithURL:urlPath];
        } else {
            DLog(@"Error: Resume action called without implementation");
        }
    }
}

- (void)_downloadTaskCallBack:(NSURLSessionDownloadTask *)sessionDownloadTask downloadItem:(OSDownloadItem *)downloadItem  {
    if (downloadItem) {
        NSDictionary *activeDownloadsDictionary = [self.activeDownloadsDictionary mutableCopy];
        [activeDownloadsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, OSDownloadItem * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj.urlPath isEqualToString:downloadItem.urlPath]) {
                [self.activeDownloadsDictionary removeObjectForKey:key];
            }
        }];
        // 将下载任务保存到activeDownloadsDictionary中
        [self.activeDownloadsDictionary setObject:downloadItem forKey:@(sessionDownloadTask.taskIdentifier)];
        
        NSString *urlPath = [downloadItem.urlPath copy];
        __weak typeof(self) weakSelf = self;
        // progress 执行 pause 时回调
        [downloadItem.naviteProgress setPausingHandler:^{
            // 暂停下载
            [weakSelf pauseWithURL:urlPath];
        }];
        // progress 执行 cancel 时回调
        [downloadItem.naviteProgress setCancellationHandler:^{
            // 取消下载
            [weakSelf cancelWithURL:urlPath];
        }];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            // progress 执行 resume 时回调 此api为9.0以上才有的，需要适配
            [downloadItem.naviteProgress setResumingHandler:^{
                // 恢复下载
                [weakSelf resumeWithURL:urlPath];
            }];
        }
        [self _anDownloadTaskWillBegin];
        
    } else {
        DLog(@"Error: No download item");
    }
}


- (void)pauseWithURL:(NSString *)urlPath {
    
    // 判断文件是否在下载中
    BOOL isDownloading = [self isDownloadingByURL:urlPath];
    // 只有在下载中才可以暂停
    if (isDownloading) {
        
        [self pauseWithURL:urlPath resumeDataHandler:^(NSData *aResumeData) {
            if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadPausedWithURL:resumeData:)]) {
                if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
                    // iOS9及以上resumeData(恢复数据)由系统管理，并在使用NSProgress调用时使用
                    //                    aResumeData = nil;
                }
                [self.downloadDelegate downloadPausedWithURL:urlPath resumeData:aResumeData];
            }
        }];

    }
    
    // 判断文件是否在等待中
    BOOL isWaiting = [self isWaitingByURL:urlPath];
    // 在等待中就移除
    if (isWaiting) {
        [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
    }
}

- (void)pauseWithURL:(NSString *)urlPath resumeDataHandler:(OSDownloaderResumeDataHandler)resumeDataHandler {
    
    // 根据downloadIdentifier获取tashIdentifier
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    
    // 当taskIdentifier>-1时有效
    if (taskIdentifier > -1) {
        [self pauseWithTaskIdentifier:taskIdentifier resumeDataHandler:resumeDataHandler];
    } else {
        [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
    }
    
}



- (void)pauseWithTaskIdentifier:(NSUInteger)taskIdentifier resumeDataHandler:(OSDownloaderResumeDataHandler)resumeDataHandler {
    
    // 从正在下载的集合中根据taskIdentifier获取到OSDownloadItem
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadItem) {
        NSURLSessionDownloadTask *downloadTask = downloadItem.sessionDownloadTask;
        if (downloadTask) {
            if (resumeDataHandler) {
                [downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                    resumeDataHandler(resumeData);
                }];
            }
            else {
                [downloadTask cancel];
            }
            // 此时会调用NSURLSessionTaskDelegate 的 URLSession:task:didCompleteWithError:
        } else {
            DLog(@"INFO: NSURLSessionDownloadTask cancelled (task not found): %@", downloadItem.urlPath);
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            // 当downloadTask不存在时执行下载失败的回调
            [self handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:taskIdentifier resumeData:nil];
        }
    }
}

- (void)cancelWithURL:(NSString *)urlPath {
    
    // 通过downloadToken获取taskIdentifier
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier > -1) {
        [self cancelWithTaskIdentifier:taskIdentifier];
    } else {
        BOOL res = [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
        if (res) {
            
            NSError *cancelError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadFailureWithDownloadItem:resumeData:error:)]) {
                OSDownloadItem *item = [[OSDownloadItem alloc] initWithURL:urlPath sessionDownloadTask:nil];
                [self.downloadDelegate downloadFailureWithDownloadItem:item resumeData:nil error:cancelError];
            }
            [self checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
            
        }
    }
}

- (void)cancelWithTaskIdentifier:(NSUInteger)taskIdentifier {
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadItem) {
        NSURLSessionDownloadTask *downloadTask = downloadItem.sessionDownloadTask;
        if (downloadTask) {
            [downloadTask cancel];
            // NSURLSessionTaskDelegate method is called
            // URLSession:task:didCompleteWithError:
        } else {
            DLog(@"INFO: NSURLSessionDownloadTask cancelled (task not found): %@", downloadItem.urlPath);
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            [self handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:taskIdentifier resumeData:nil];
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (BOOL)removeDownloadTaskFromWaitingDownloadArrayByUrlPath:(NSString *)url {
    NSInteger foundIdx = [self.waitingDownloadArray indexOfObjectPassingTest:
                          ^BOOL(NSDictionary<NSString *,NSObject *> * _Nonnull waitingDownloadDict, NSUInteger idx, BOOL * _Nonnull stop) {
                              NSString *waitingUrlPath = (NSString *)waitingDownloadDict[OSDownloadURLKey];
                              return [url isKindOfClass:[NSString class]] && [url isEqualToString:waitingUrlPath];
                          }];
    if (foundIdx != NSNotFound) {
        [self.waitingDownloadArray removeObjectAtIndex:foundIdx];
        return YES;
    }
    return NO;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - download status
////////////////////////////////////////////////////////////////////////

- (BOOL)isDownloadingByURL:(NSString *)urlPath {
    
    __block BOOL isDownloading = NO;
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier > -1) {
        OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
        if (downloadItem) {
            isDownloading = YES;
        }
    }
    
//    if (!isDownloading) {
//        [self.waitingDownloadArray  enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull waitingDownloadDict, NSUInteger idx, BOOL * _Nonnull stop) {
//            if ([waitingDownloadDict[OSDownloadURLKey] isKindOfClass:[NSString class]]) {
//                NSString *waitingUrlPath = (NSString *)waitingDownloadDict[OSDownloadURLKey];
//                if ([waitingUrlPath isEqualToString:urlPath]) {
//                    isDownloading = YES;
//                    *stop = YES;
//                }
//            }
//        }];
//    }
    return isDownloading;
}

- (BOOL)isWaitingByURL:(NSString *)urlPath {
    __block BOOL isWaiting = NO;
    
    [self.waitingDownloadArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull waitingDownloadDict, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([waitingDownloadDict[OSDownloadURLKey] isKindOfClass:[NSString class]]) {
            NSString *waitingUrlPath = (NSString *)waitingDownloadDict[OSDownloadURLKey];
            if ([waitingUrlPath isEqualToString:urlPath]) {
                isWaiting = YES;
                *stop = YES;
            }
        }
    }];
    
    //    NSInteger taskIdentifer = [self getDownloadTaskIdentifierByURL:urlPath];
    //    if (taskIdentifer > -1) {
    //        OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifer)];
    //        if (downloadItem && downloadItem.receivedFileSize == 0) {
    //            isWaiting = YES;
    //        }
    //    }
    
    return isWaiting;
}

- (BOOL)hasActiveDownloads {
    BOOL isHasActive = NO;
    if (self.activeDownloadsDictionary.count || self.waitingDownloadArray.count) {
        isHasActive = YES;
    }
    return isHasActive;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - download Handler
////////////////////////////////////////////////////////////////////////


/// 下载成功并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadItem:(OSDownloadItem *)downloadItem
                               taskIdentifier:(NSUInteger)taskIdentifier {
    
    downloadItem.naviteProgress.completedUnitCount = downloadItem.naviteProgress.totalUnitCount;
    [self.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self _anDownloadTaskDidEnd];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate downloadSuccessnWithDownloadItem:downloadItem];
    });
    [self checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}


/// 下载取消、失败时回调
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadItem:(OSDownloadItem *)downloadItem
                        taskIdentifier:(NSUInteger)taskIdentifier
                            resumeData:(NSData *)resumeData {
    //    downloadItem.naviteProgress.completedUnitCount = downloadItem.naviteProgress.totalUnitCount;
    [self.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self _anDownloadTaskDidEnd];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate downloadFailureWithDownloadItem:downloadItem resumeData:resumeData error:error];
    });
    
    
    
    [self checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}

/// 检查当前同时下载的任务数量是否超出最大值maxConcurrentDownloadCount
/// @mark 当当前正在下载的activeDownloadsDictionary任务中小于最大同时下载数量时，
///  @mark 则从等待的waitingDownloadArray中取出第一个开始下载，添加到activeDownloadsDictionary，并从waitingDownloadArray中移除
- (void)checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded {
    
    if (self.maxConcurrentDownloads == -1 || self.activeDownloadsDictionary.count < self.maxConcurrentDownloads) {
        // 判断等待中是否有任务等待
        if (self.waitingDownloadArray.count) {
            // 取出waitingDownloadArray中最前面的下载
            NSDictionary *waitingDownTaskDict = [self.waitingDownloadArray firstObject];
            NSData *resumeData = waitingDownTaskDict[OSDownloadResumeDataKey];
            [self downloadWithURL:waitingDownTaskDict[OSDownloadURLKey] resumeData:resumeData];
            // 取出前面的下载后会添加到activeDownloadsDictionary，从waitingDownloadArray中移除
            [self.waitingDownloadArray removeObjectAtIndex:0];
            [self _startDownloadTaskFromTheWaitingQueue:waitingDownTaskDict[OSDownloadURLKey]];
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - download progress
////////////////////////////////////////////////////////////////////////


- (OSDownloadProgress *)getDownloadProgressByURL:(NSString *)urlPath {
    OSDownloadProgress *downloadProgress = nil;
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier > -1) {
        downloadProgress = [self downloadProgressByTaskIdentifier:taskIdentifier];
    }
    return downloadProgress;
}


/// 根据taskIdentifier 创建 OSDownloadProgress 对象
- (OSDownloadProgress *)downloadProgressByTaskIdentifier:(NSUInteger)taskIdentifier {
    OSDownloadProgress *progressObj = nil;
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadItem) {
        float progress = 0.0;
        if (downloadItem.expectedFileTotalSize > 0) {
            progress = (float)downloadItem.receivedFileSize / (float)downloadItem.expectedFileTotalSize;
        }
        NSDictionary *remainingTimeDict = [[self class] remainingTimeAndBytesPerSecondForDownloadItem:downloadItem];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            [downloadItem.naviteProgress setUserInfoObject:[remainingTimeDict objectForKey:OSDownloadRemainingTimeKey] forKey:NSProgressEstimatedTimeRemainingKey];
            [downloadItem.naviteProgress setUserInfoObject:[remainingTimeDict objectForKey:OSDownloadBytesPerSecondSpeedKey] forKey:NSProgressThroughputKey];
        }
        
        progressObj = [[OSDownloadProgress alloc] initWithDownloadProgress:progress
                                                          expectedFileSize:downloadItem.expectedFileTotalSize
                                                          receivedFileSize:downloadItem.receivedFileSize
                                                    estimatedRemainingTime:[remainingTimeDict[OSDownloadRemainingTimeKey] doubleValue]
                                                       bytesPerSecondSpeed:[remainingTimeDict[OSDownloadBytesPerSecondSpeedKey] unsignedIntegerValue]
                                                            nativeProgress:downloadItem.naviteProgress];
    }
    return progressObj;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDownloadDelegate
////////////////////////////////////////////////////////////////////////

/// 下载完成之后回调
- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    
    NSString *errorStr = nil;
    
    // 获取当前downloadTask对应的OSDownloadItem
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(downloadTask.taskIdentifier)];
    if (!downloadItem) {
        NSProgress *rootProgress = [self _createNativeProgress];
        rootProgress.totalUnitCount++;
        // UnitCount是一个基于UI上的完整任务的单元数
        // 将此rootProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
        [rootProgress becomeCurrentWithPendingUnitCount:1];
        
        downloadItem = [[OSDownloadItem alloc] initWithURL:downloadTask.taskDescription
                                                       sessionDownloadTask:downloadTask];
        // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用
        [rootProgress resignCurrent];
        
        [self _downloadTaskCallBack:downloadTask downloadItem:downloadItem];
    }
    if (downloadItem) {
        
        NSURL *finalLocalFileURL = nil;
        NSURL *remoteURL = [[downloadTask.originalRequest URL] copy];
        if (remoteURL) {
            finalLocalFileURL = [self _getFinalLocalFileURLWithRemoteURL:remoteURL];
            downloadItem.finalLocalFileURL = finalLocalFileURL;
        } else {
            errorStr = [NSString stringWithFormat:@"Error: Missing information: Remote URL (token: %@)", downloadItem.urlPath];
            DLog(@"%@", errorStr);
        }
        
        if (finalLocalFileURL) {
            // 从临时文件目录移动文件到最终位置
            BOOL moveFlag = [self _moveFileAtURL:location toURL:finalLocalFileURL errorStr:&errorStr];
            if (moveFlag) {
                // 移动文件成功 验证文件是否有效
                [self _isVaildDownloadFileByDownloadIdentifier:downloadItem.urlPath finalLocalFileURL:finalLocalFileURL errorStr:&errorStr];
            }
            
        } else {
            // 获取最终存储文件的url为nil
            errorStr = [NSString stringWithFormat:@"Error: Missing information: Local file URL (token: %@)", downloadItem.urlPath];
            DLog(@"%@", errorStr);
        }
        
        if (errorStr) {
            // 将错误信息添加到errorMessagesStack中
            NSMutableArray *errorMessagesStack = [downloadItem.errorMessagesStack mutableCopy];
            if (!errorMessagesStack) {
                errorMessagesStack = [NSMutableArray array];
            }
            [errorMessagesStack insertObject:errorStr atIndex:0];
            [downloadItem setErrorMessagesStack:errorMessagesStack];
        } else {
            downloadItem.finalLocalFileURL = finalLocalFileURL;
        }
    } else {
        DLog(@"Error: 通过downloadTask.taskIdentifier未获取到downloadItem: %@", @(downloadTask.taskIdentifier));
        
    }
    
}

/// 当接收到下载数据的时候调用,监听文件下载的进度 该方法会被调用多次
/// totalBytesWritten:已经写入到文件中的数据大小
/// totalBytesExpectedToWrite:目前文件的总大小
/// bytesWritten:本次下载的文件数据大小
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    // 通过downloadTask.taskIdentifier获取OSDownloadItem对象
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(downloadTask.taskIdentifier)];
    if (!downloadItem) {
        NSProgress *rootProgress = [self _createNativeProgress];
        rootProgress.totalUnitCount++;
        // UnitCount是一个基于UI上的完整任务的单元数
        // 将此rootProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
        [rootProgress becomeCurrentWithPendingUnitCount:1];
        
        downloadItem = [[OSDownloadItem alloc] initWithURL:downloadTask.taskDescription
                                                       sessionDownloadTask:downloadTask];
        // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用
        [rootProgress resignCurrent];
        
        [self _downloadTaskCallBack:downloadTask downloadItem:downloadItem];
    }
    if (downloadItem) {
        if (!downloadItem.downloadStartDate) {
            downloadItem.downloadStartDate = [NSDate date];
            downloadItem.bytesPerSecondSpeed = 0;
        }
        downloadItem.receivedFileSize = totalBytesWritten;
        downloadItem.expectedFileTotalSize = totalBytesExpectedToWrite;
        NSString *taskDescription = [downloadTask.taskDescription copy];
        [self _progressChangeWithURL:taskDescription];
    }
    
}

/// 恢复下载的时候调用该方法
/// fileOffset:恢复之后，要从文件的什么地方开发下载
/// expectedTotalBytes：该文件数据的预计总大小
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(downloadTask.taskIdentifier)];
    if (downloadItem) {
        downloadItem.resumedFileSizeInBytes = fileOffset;
        downloadItem.downloadStartDate = [NSDate date];
        downloadItem.bytesPerSecondSpeed = 0;
        DLog(@"INFO: Download (id: %@) resumed (offset: %@ bytes, expected: %@ bytes", downloadTask.taskDescription, @(fileOffset), @(expectedTotalBytes));
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionTaskDelegate
////////////////////////////////////////////////////////////////////////

/// 当请求完成之后调用该方法
/// 不论是请求成功还是请求失败都调用该方法，如果请求失败，那么error对象有值，否则那么error对象为空
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(task.taskIdentifier)];
    if (!downloadItem) {
        if (!downloadItem) {
            NSProgress *rootProgress = [self _createNativeProgress];
            rootProgress.totalUnitCount++;
            // UnitCount是一个基于UI上的完整任务的单元数
            // 将此rootProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
            [rootProgress becomeCurrentWithPendingUnitCount:1];
            
            downloadItem = [[OSDownloadItem alloc] initWithURL:task.taskDescription
                                                           sessionDownloadTask:task];
            // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用
            [rootProgress resignCurrent];
            
            [self _downloadTaskCallBack:task downloadItem:downloadItem];
        }

    }
    if (downloadItem) {
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        
        NSHTTPURLResponse *aHttpResponse = (NSHTTPURLResponse *)task.response;
        NSInteger httpStatusCode = aHttpResponse.statusCode;
        downloadItem.lastHttpStatusCode = httpStatusCode;
        downloadItem.MIMEType = task.response.MIMEType;
        if (error == nil) {
            BOOL httpStatusCodeIsCorrectFlag = [self _isVaildHTTPStatusCode:httpStatusCode url:downloadItem.urlPath];
            if (httpStatusCodeIsCorrectFlag == YES) {
                NSURL *finalLocalFileURL = downloadItem.finalLocalFileURL;
                if (finalLocalFileURL) {
                    [self handleDownloadSuccessWithDownloadItem:downloadItem taskIdentifier:task.taskIdentifier];
                } else {
                    NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil];
                    [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:resumeData];
                }
            } else {
                NSString *errorString = [NSString stringWithFormat:@"Invalid http status code: %@", @(httpStatusCode)];
                NSMutableArray<NSString *> *errorMessagesStackArray = [downloadItem.errorMessagesStack mutableCopy];
                if (errorMessagesStackArray == nil) {
                    errorMessagesStackArray = [NSMutableArray array];
                }
                [errorMessagesStackArray insertObject:errorString atIndex:0];
                [downloadItem setErrorMessagesStack:errorMessagesStackArray];
                
                NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
                [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:resumeData];
            }
        } else {
            
            //NSString *aFailingURLStringErrorKeyString = [anError.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
            //NSNumber *aBackgroundTaskCancelledReasonKeyNumber = [anError.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey];
            [self handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:resumeData];
        }
    } else {
        DLog(@"Error: Download item not found for download task: %@", task);
        
        NSData *resumeData = error ? [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]:nil;
        if (resumeData) {
            NSURL *resumeDataCachePath = [[self downloaderFolderPath] URLByAppendingPathComponent:task.taskDescription.lastPathComponent];
            [resumeData writeToURL:resumeDataCachePath atomically:YES];
            
        }else {
            [self deleteFileIfExist:task.taskDescription];
        }
        
    }
}


/// SSL / TLS 验证
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    if ([self.downloadDelegate respondsToSelector:@selector(authenticationChallenge:url:completionHandler:)]) {
        NSString *urlPath = [task.taskDescription copy];
        if (urlPath) {
            [self.downloadDelegate authenticationChallenge:challenge
                                                       url:urlPath
                                         completionHandler:^(NSURLCredential * _Nullable aCredential, NSURLSessionAuthChallengeDisposition aDisposition) {
                                             completionHandler(aDisposition, aCredential);
                                         }];
        } else {
            DLog(@"Error: Missing task description");
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    } else {
        DLog(@"Error: Received authentication challenge with no delegate method implemented");
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDelegate
////////////////////////////////////////////////////////////////////////

/// 后台任务完成时调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.backgroundSessionCompletionHandler) {
        OSBackgroundSessionCompletionHandler completionHandler = self.backgroundSessionCompletionHandler;
        self.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
}

/// 当不再需要连接调用Session的invalidateAndCancel直接关闭，或者调用finishTasksAndInvalidate等待当前Task结束后关闭
/// 此时此方法会收到回调
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DLog(@"Error: URL session did become invalid with error: %@", error);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private delegate methods
////////////////////////////////////////////////////////////////////////

/// 有一个任务等待下载时调用
- (void)_didWaitingDownloadForUrlPath:(NSString *)url {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadDidWaitingWithURLPath:progress:)]) {
        OSDownloadProgress *progress = [self getDownloadProgressByURL:url];
        [self.downloadDelegate downloadDidWaitingWithURLPath:url progress:progress];
    }
}

/// 从等待队列中开始下载一个任务
- (void)_startDownloadTaskFromTheWaitingQueue:(NSString *)url {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadStartFromWaitingQueueWithURLpath:progress:)]) {
        OSDownloadProgress *progress = [self getDownloadProgressByURL:url];
        [self.downloadDelegate downloadStartFromWaitingQueueWithURLpath:url progress:progress];
    }
}


/// 获取下载后文件最终存放的本地路径,若代理实现了则设置使用代理的，没实现则使用默认设定的LocalURL
- (NSURL *)_getFinalLocalFileURLWithRemoteURL:(NSURL *)remoteURL {
    NSURL *finalUrl = nil;
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(finalLocalFileURLWithRemoteURL:)]) {
        finalUrl = [self.downloadDelegate finalLocalFileURLWithRemoteURL:remoteURL];
    } else {
        finalUrl = [self getDefaultLocalFilePathWithRemoteURL:remoteURL];
    }
    
    return finalUrl;
}

- (NSURL *)downloaderFolderPath {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(finalLocalFolderURL)]) {
        return [self.downloadDelegate finalLocalFolderURL];
    }
    return [[self class] getDefaultLocalFolderPath];
}

/// 验证下载的文件是否有效
- (BOOL)_isVaildDownloadFileByDownloadIdentifier:(NSString *)identifier
                               finalLocalFileURL:(NSURL *)finalLocalFileURL errorStr:(NSString **)errorStr {
    BOOL isVaild = YES;
    
    // 移动到最终位置成功
    NSError *error = nil;
    // 获取最终文件的属性
    NSDictionary *finalFileAttributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:finalLocalFileURL.path error:&error];
    if (error && errorStr) {
        *errorStr = [NSString stringWithFormat:@"Error: Error on getting file size for item at %@: %@", finalLocalFileURL, error.localizedDescription];
        DLog(@"%@", *errorStr);
        isVaild = NO;
    } else {
        // 成功获取到文件的属性
        // 获取文件的尺寸 判断移动后的文件是否有效
        unsigned long long fileSize = [finalFileAttributesDictionary fileSize];
        if (fileSize == 0) {
            // 文件大小字节数为0 不正常
            NSError *fileSizeZeroError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorZeroByteResource userInfo:nil];
            *errorStr = [NSString stringWithFormat:@"Error: Zero file size for item at %@: %@", finalLocalFileURL, fileSizeZeroError.localizedDescription];
            DLog(@"%@", *errorStr);
            isVaild = NO;
        } else {
            if ([self.downloadDelegate respondsToSelector:@selector(downloadFinalLocalFileURL:isVaildByURL:)]) {
                BOOL isVaild = [self.downloadDelegate downloadFinalLocalFileURL:finalLocalFileURL isVaildByURL:identifier];
                if (isVaild == NO) {
                    *errorStr = [NSString stringWithFormat:@"Error: Download check failed for item at %@", finalLocalFileURL];
                    DLog(@"%@", *errorStr);
                }
            }
        }
    }
    
    return isVaild;
}

/// 将文件从临时目录移动到最终的目录
- (BOOL)_moveFileAtURL:(NSURL *)fromURL toURL:(NSURL *)toURL errorStr:(NSString **)errorStr {
    
    // 判断之前localFileURL的位置是否有文件存储，如果存在就删除掉
    if ([[NSFileManager defaultManager] fileExistsAtPath:toURL.path]) {
        NSError *removeError = nil;
        [[NSFileManager defaultManager] removeItemAtURL:toURL error:&removeError];
        if (removeError && errorStr) {
            *errorStr = [NSString stringWithFormat:@"Error: Error on removing file at %@: %@", toURL, removeError];
            DLog(@"%@", *errorStr);
        }
    }
    
    // 将服务器下载完保存的临时位置移动到最终存储的位置
    NSError *error = nil;
    BOOL successFlag = [[NSFileManager defaultManager] moveItemAtURL:fromURL toURL:toURL error:&error];
    if (successFlag == NO) {
        // 从location临时路径移动到最终路径失败
        NSError *moveError = error;
        if (moveError == nil) {
            moveError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCannotMoveFile userInfo:nil];
        }
        if (errorStr) {
            *errorStr = [NSString stringWithFormat:@"Error: Unable to move file from %@ to %@ (%@)", fromURL, toURL, moveError.localizedDescription];
        }
        DLog(@"%@", *errorStr);
    }
    return successFlag;
}

/// 根据服务器响应的HttpStatusCode验证服务器响应状态
- (BOOL)_isVaildHTTPStatusCode:(NSUInteger)httpStatusCode
                           url:(NSString *)urlPath {
    BOOL httpStatusCodeIsCorrectFlag = NO;
    if ([self.downloadDelegate respondsToSelector:@selector(httpStatusCode:isVaildByURL:)]) {
        httpStatusCodeIsCorrectFlag = [self.downloadDelegate httpStatusCode:httpStatusCode isVaildByURL:urlPath];
    } else {
        httpStatusCodeIsCorrectFlag = [[self class] isValidHttpStatusCode:httpStatusCode];
    }
    return httpStatusCodeIsCorrectFlag;
}

/// 进度改变时更新进度
- (void)_progressChangeWithURL:(NSString *)urlPath {
    
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadProgressChangeWithURL:progress:)]) {
        if (urlPath) {
            OSDownloadProgress *progress = [self getDownloadProgressByURL:urlPath];
            [self.downloadDelegate downloadProgressChangeWithURL:urlPath progress:progress];
        }
        
    }
    
}

// 创建并配置backgroundConfiguration
// 如果代理实现了自定义后台会话配置方法,就按照代理的配置
- (NSURLSessionConfiguration *)_createBackgroundSessionConfig {
    // 创建后台会话配置对象
    NSURLSessionConfiguration *backgroundConfiguration = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundDownloadSessionIdentifier];
    } else {
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:kBackgroundDownloadSessionIdentifier];
    }
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(customBackgroundSessionConfiguration:)]) {
        [self.downloadDelegate customBackgroundSessionConfiguration:backgroundConfiguration];
    } else {
        // 同时设置值timeoutIntervalForRequest和timeoutIntervalForResource值NSURLSessionConfiguration，较小的值会受到影响
        // 请求超时时间；默认为60秒
        backgroundConfiguration.timeoutIntervalForRequest = 180;
        // 是否允许蜂窝网络访问（2G/3G/4G）
        //        backgroundConfiguration.allowsCellularAccess = NO;
        // 限制每次最多连接数；在 iOS 中默认值为4
        // backgroundConfiguration.HTTPMaximumConnectionsPerHost = self.maxConcurrentDownloads;
        // 允许后台任务按系统的最佳时间安排，以获得最佳性能 (仅background session有效)
        // 设置discretionary = YES 后，若iPhone未连接电源则下载没有任何响应，连接电源后立即可以下载
        backgroundConfiguration.discretionary = NO;
    }
    return backgroundConfiguration;
}

/// 创建NSProgress
- (NSProgress *)_createNativeProgress {
    NSProgress *progress = nil;
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(usingNaviteProgress)]) {
        progress = [self.downloadDelegate usingNaviteProgress];
    }
    return progress;
}

/// 即将开始下载时调用
- (void)_anDownloadTaskWillBegin {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadTaskWillBegin)]) {
        [self.downloadDelegate downloadTaskWillBegin];
    }
}

/// 已经结束某个任务，不管是否成功都会调用
- (void)_anDownloadTaskDidEnd {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadTaskDidEnd)]) {
        [self.downloadDelegate downloadTaskDidEnd];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////

/// 通过downloadToken获取下载任务的TaskIdentifier
- (NSInteger)getDownloadTaskIdentifierByURL:(nonnull NSString *)urlPath {
    NSInteger taskIdentifier = -1;
    NSArray *aDownloadKeysArray = [self.activeDownloadsDictionary allKeys];
    for (NSNumber *identifier in aDownloadKeysArray)
    {
        OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:identifier];
        if ([downloadItem.urlPath isEqualToString:urlPath]) {
            taskIdentifier = [identifier unsignedIntegerValue];
            break;
        }
    }
    return taskIdentifier;
}

/// 默认缓存下载文件的本地文件夹
+ (NSURL *)getDefaultLocalFolderPath {
    NSURL *aFileDownloadDirectoryURL = nil;
    NSError *anError = nil;
    NSArray *documentDirectoryURLsArray = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = [documentDirectoryURLsArray firstObject];
    if (documentsDirectoryURL)
    {
        aFileDownloadDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:OSDownloaderFolderNameKey isDirectory:YES];
        if ([[NSFileManager defaultManager] fileExistsAtPath:aFileDownloadDirectoryURL.path] == NO)
        {
            BOOL aCreateDirectorySuccess = [[NSFileManager defaultManager] createDirectoryAtPath:aFileDownloadDirectoryURL.path withIntermediateDirectories:YES attributes:nil error:&anError];
            if (aCreateDirectorySuccess == NO)
            {
                DLog(@"Error on create directory: %@", anError);
            }
            else
            {
                // 排除备份，即使文件存储在document中，该目录下载的文件也不会被备份到itunes或上传的iCloud中
                BOOL aSetResourceValueSuccess = [aFileDownloadDirectoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&anError];
                if (aSetResourceValueSuccess == NO)
                {
                    DLog(@"Error on set resource value (NSURLIsExcludedFromBackupKey): %@", anError);
                }
            }
        }
        return aFileDownloadDirectoryURL;
    }
    return nil;
    
}

/// 获取下载的文件默认存储在背的的位置，若代理未实现时则使用此默认的
- (NSURL *)getDefaultLocalFilePathWithRemoteURL:(NSURL *)remoteURL {
    NSURL *aLocalFileURL = nil;
    NSURL *aFileDownloadDirectoryURL = [self downloaderFolderPath];
    NSString *aLocalFileName = [NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], [[remoteURL lastPathComponent] pathExtension]];
    aLocalFileURL = [aFileDownloadDirectoryURL URLByAppendingPathComponent:aLocalFileName isDirectory:NO];
    
    return aLocalFileURL;
}

+ (BOOL)isValidHttpStatusCode:(NSInteger)aHttpStatusCode {
    BOOL anIsCorrectFlag = NO;
    if ((aHttpStatusCode >= 200) && (aHttpStatusCode < 300))
    {
        anIsCorrectFlag = YES;
    }
    return anIsCorrectFlag;
}


/// 计算当前下载的剩余时间和每秒下载的字节数
+ (NSDictionary *)remainingTimeAndBytesPerSecondForDownloadItem:(nonnull OSDownloadItem *)aDownloadItem {
    // 下载剩余时间
    NSTimeInterval remainingTimeInterval = 0.0;
    // 当前下载的速度
    NSUInteger bytesPerSecondsSpeed = 0;
    if ((aDownloadItem.receivedFileSize > 0) && (aDownloadItem.expectedFileTotalSize > 0)) {
        float aSmoothingFactor = 0.8; // range 0.0 ... 1.0 (determines the weight of the current speed calculation in relation to the stored past speed value)
        NSTimeInterval downloadDurationUntilNow = [[NSDate date] timeIntervalSinceDate:aDownloadItem.downloadStartDate];
        int64_t aDownloadedFileSize = aDownloadItem.receivedFileSize - aDownloadItem.resumedFileSizeInBytes;
        float aCurrentBytesPerSecondSpeed = (downloadDurationUntilNow > 0.0) ? (aDownloadedFileSize / downloadDurationUntilNow) : 0.0;
        float aNewWeightedBytesPerSecondSpeed = 0.0;
        if (aDownloadItem.bytesPerSecondSpeed > 0.0)
        {
            aNewWeightedBytesPerSecondSpeed = (aSmoothingFactor * aCurrentBytesPerSecondSpeed) + ((1.0 - aSmoothingFactor) * (float)aDownloadItem.bytesPerSecondSpeed);
        } else {
            aNewWeightedBytesPerSecondSpeed = aCurrentBytesPerSecondSpeed;
        } if (aNewWeightedBytesPerSecondSpeed > 0.0) {
            remainingTimeInterval = (aDownloadItem.expectedFileTotalSize - aDownloadItem.resumedFileSizeInBytes - aDownloadedFileSize) / aNewWeightedBytesPerSecondSpeed;
        }
        bytesPerSecondsSpeed = (NSUInteger)aNewWeightedBytesPerSecondSpeed;
        aDownloadItem.bytesPerSecondSpeed = bytesPerSecondsSpeed;
    }
    return @{
             OSDownloadBytesPerSecondSpeedKey : @(bytesPerSecondsSpeed),
             OSDownloadRemainingTimeKey: @(remainingTimeInterval)};
}


- (void)dealloc {
    
    [self.backgroundSeesion finishTasksAndInvalidate];
}


- (NSString *)description {
    NSMutableDictionary *aDescriptionDict = [NSMutableDictionary dictionary];
    [aDescriptionDict setObject:self.activeDownloadsDictionary forKey:@"activeDownloadsDictionary"];
    [aDescriptionDict setObject:self.waitingDownloadArray forKey:@"waitingDownloadsArray"];
    [aDescriptionDict setObject:@(self.maxConcurrentDownloads) forKey:@"maxConcurrentFileDownloadsCount"];
    
    NSString *aDescriptionString = [NSString stringWithFormat:@"%@", aDescriptionDict];
    
    return aDescriptionString;
}


- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _maxConcurrentDownloads = -1;
    if (maxConcurrentDownloads > _maxConcurrentDownloads) {
        _maxConcurrentDownloads = maxConcurrentDownloads;
        [self checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
    }
}

- (NSInteger)maxConcurrentDownloads {
    return _maxConcurrentDownloads ?: -1;
}

- (NSOperationQueue *)backgroundSeesionQueue {
    if (!_backgroundSeesionQueue) {
        _backgroundSeesionQueue = [NSOperationQueue new];
        _backgroundSeesionQueue.maxConcurrentOperationCount = 1;
        _backgroundSeesionQueue.name = @"com.sey.FileDownloaderQueue";
    }
    return _backgroundSeesionQueue;
}

- (NSMutableDictionary<NSNumber *,OSDownloadItem *> *)activeDownloadsDictionary {
    if (!_activeDownloadsDictionary) {
        _activeDownloadsDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return _activeDownloadsDictionary;
}

- (NSMutableArray<NSDictionary<NSString *,NSObject *> *> *)waitingDownloadArray {
    if (!_waitingDownloadArray) {
        _waitingDownloadArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _waitingDownloadArray;
}

- (BOOL)__isValidResumeData:(NSData *)data{
    if (!data || [data length] < 1) {
        return NO;
    }
    
    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) {
        return NO;
    }
    return YES;
//    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
//    if ([localFilePath length] < 1) {
//        return NO;
//    }
//    
//    BOOL res = [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
//    return res;
}

/// 检测当前正在下载的队列是否超出最大设定的
//- (void)checkDownloadingQueueIsAboveMaxConcurrentDownloads {
//    if (_maxConcurrentDownloads == -1) {
//        return;
//    }
//
//    __block NSInteger downnloadingIdx = 0;
//    [self.activeDownloadsDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, OSDownloadItem * _Nonnull obj, BOOL * _Nonnull stop) {
//        if ([self isDownloadingByURL:obj.urlPath]) {
//            downnloadingIdx++;
//        }
//    }];
//    if (downnloadingIdx > self.maxConcurrentDownloads) {
//        // 当前正在下载的总数大于最大设定值，暂停最后添加到activeDownloadsDictionary中的正在下载的item
//        NSInteger count = downnloadingIdx - self.maxConcurrentDownloads;
//        [self.activeDownloadsDictionary enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber * _Nonnull key, OSDownloadItem * _Nonnull obj, BOOL * _Nonnull stop) {
//            if () {
//
//            }
//        }];
//    }
//}


- (void)deleteFileIfExist:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        NSError *error  = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (error) {
            DLog(@"emoveItem error %@",error);
        }
    }
}

__unused static void semaphore_autoreleasepoolBlock (void (^block)())
{
    static dispatch_semaphore_t lockSemaphore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lockSemaphore = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lockSemaphore, DISPATCH_TIME_FOREVER);
    @autoreleasepool {
        if (block) {
            block();
        }
    }
    dispatch_semaphore_signal(lockSemaphore);
}

- (void)lock
{
    dispatch_semaphore_wait(_lockSemaphore, DISPATCH_TIME_FOREVER);
}

- (void)unlock
{
    dispatch_semaphore_signal(_lockSemaphore);
}

@end
