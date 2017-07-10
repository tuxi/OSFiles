//
//  OSDownloader.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloader.h"
#import "NSURLSession+CorrectedResumeData.h"
#import "OSDownloaderSessionPrivateDelegate.h"
#import "OSDownloadItem.h"

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
@property (nonatomic, strong) NSOperationQueue *backgroundSeesionQueue;
@property (nonatomic, strong) NSURL *downloaderFolderPath;
@property (nonatomic, strong) NSLock *lock_;
@property (nonatomic, strong) OSDownloaderSessionPrivateDelegate *sessionDelegate;

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
        _sessionDelegate = [[OSDownloaderSessionPrivateDelegate alloc] initWithDownloader:self];
        _backgroundSeesion = [NSURLSession sessionWithConfiguration:[self createBackgroundSessionConfig] delegate:self delegateQueue:self.backgroundSeesionQueue];
        _backgroundSeesion.sessionDescription = @"OSDownload_BackgroundSession";
        _lock_ = [NSLock new];
    }
    return self;
}


- (void)setDownloadDelegate:(id<OSDownloaderDelegate>)downloadDelegate {
    if (_downloadDelegate == downloadDelegate) {
        return;
    }
    _downloadDelegate = downloadDelegate;
    self.sessionDelegate.downloadDelegate = downloadDelegate;
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

- (OSDownloadItem *)getDownloadItemByDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    OSDownloadItem *downloadItem = nil;
    downloadItem = [self.activeDownloadsDictionary objectForKey:@(downloadTask.taskIdentifier)];
    if (downloadItem) {
        return downloadItem;
    }
    NSString *urlPath = [[downloadTask taskDescription] copy];
    if (urlPath) {
        NSProgress *progress = [self.sessionDelegate progress];
        progress.totalUnitCount++;
        // UnitCount是一个基于UI上的完整任务的单元数
        // 将此rootProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
        [progress becomeCurrentWithPendingUnitCount:1];
        
        downloadItem = [[OSDownloadItem alloc] initWithURL:urlPath
                                       sessionDownloadTask:downloadTask];
        // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用
        [progress resignCurrent];
        
        [self _downloadTaskCallBack:downloadTask downloadItem:downloadItem];
    }
    
    return downloadItem;
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Download
////////////////////////////////////////////////////////////////////////

- (void)downloadWithURL:(NSString *)urlPath {
    [self downloadWithURL:urlPath resumeData:nil];
}


- (void)downloadWithURL:(NSString *)urlPath resumeData:(NSData *)resumeData {
    [self lock];
    __weak typeof(self) weakSelf = self;
    dispatch_block_t downloadBlock = ^{
        NSUInteger taskIdentifier = 0;
        NSURL *remoteURL = [NSURL URLWithString:urlPath];
        BOOL isValidResumeData = [weakSelf __isValidResumeData:resumeData];
        // 当前同时下载的数量是否超出最大的设定
        if (weakSelf.maxConcurrentDownloads == NSIntegerMax || weakSelf.activeDownloadsDictionary.count < weakSelf.maxConcurrentDownloads) {
            
            NSURLSessionDownloadTask *sessionDownloadTask = nil;
            OSDownloadItem *downloadItem = nil;
            NSProgress *naviteProgress = [self.sessionDelegate progress];
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
            [weakSelf.sessionDelegate _didWaitingDownloadForUrlPath:urlPath];
        }
        
    };
    
    /// 通过getTasksWithCompletionHandler 获取到的sessionDownloadTask去恢复下载，这样系统可以解决比如app突然重启时resumeData未保存起来，再次启动app时无remuseData而断点续传的问题
    __unused void (^downloadWithgetTask)(NSURLSessionDownloadTask *) = ^(NSURLSessionDownloadTask *sessionDownloadTask){
        [self getDownloadItemByDownloadTask:sessionDownloadTask];
        [sessionDownloadTask resume];
    };
    

    [self getDownloadTasks:^(NSArray *downloadTasks) {
        if (downloadTasks.count) {
            for (NSURLSessionDownloadTask *task in downloadTasks) {
                // 不在当前活跃的任务，并且不是当前需要下载的url 就取消掉任务
                NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:task.taskDescription];
                if (taskIdentifier < 0) {
                    if (![task.taskDescription isEqualToString:urlPath]) {
                        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                            
                        }];
                    }
                }
            }
        }
        NSUInteger foundIdxInDownloadTasks = [downloadTasks indexOfObjectPassingTest:^BOOL(NSURLSessionDownloadTask *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.taskDescription isEqualToString:urlPath];
        }];
        if (foundIdxInDownloadTasks != NSNotFound) {
            NSURLSessionDownloadTask *downloadTask = [downloadTasks objectAtIndex:foundIdxInDownloadTasks];
            downloadWithgetTask(downloadTask);
        } else {
            downloadBlock();
        }
    }];

    [self unLock];
}



/// 通过urlPath恢复下载
- (void)resumeWithURL:(NSString *)urlPath {
    [self lock];
    // 判断文件是否在下载中
    BOOL isDownloading = [self isDownloading:urlPath];
    // 如果不在下载中，就执行恢复
    if (!isDownloading) {
        [self.sessionDelegate _resumeWithURL:urlPath];
    }
    [self unLock];
}

- (void)_downloadTaskCallBack:(NSURLSessionDownloadTask *)sessionDownloadTask downloadItem:(OSDownloadItem *)downloadItem  {
    if (downloadItem) {
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
        [self.sessionDelegate _anDownloadTaskWillBegin];
        
    } else {
        DLog(@"Error: No download item");
    }
}


- (void)pauseWithURL:(NSString *)urlPath {
    [self lock];
    // 判断文件是否在下载中
    BOOL isDownloading = [self isDownloading:urlPath];
    // 只有在下载中才可以暂停
    if (isDownloading) {
        
        [self pauseWithURL:urlPath resumeDataHandler:^(NSData *resumeData) {
            [self.sessionDelegate _pauseWithURL:urlPath resumeData:resumeData];
        }];
        
    }
    
    // 判断文件是否在等待中
    BOOL isWaiting = [self isWaiting:urlPath];
    // 在等待中就移除
    if (isWaiting) {
        [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
    }
    [self unLock];
}

- (void)pauseWithURL:(NSString *)urlPath resumeDataHandler:(OSDownloaderResumeDataHandler)resumeDataHandler {
    
    // 根据downloadIdentifier获取tashIdentifier
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    
    // 当taskIdentifier!=NSNotFound时有效
    if (taskIdentifier != NSNotFound) {
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
            [self.sessionDelegate handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:taskIdentifier resumeData:nil];
        }
    }
}

- (void)cancelWithURL:(NSString *)urlPath {
    [self lock];
    // 通过downloadToken获取taskIdentifier
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier != NSNotFound) {
        [self cancelWithTaskIdentifier:taskIdentifier];
    } else {
        BOOL res = [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
        if (res) {
            
            NSError *cancelError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            OSDownloadItem *item = [[OSDownloadItem alloc] initWithURL:urlPath sessionDownloadTask:nil];
            [self.sessionDelegate handleDownloadFailureWithError:cancelError downloadItem:item taskIdentifier:NSNotFound resumeData:nil];
        }
    }
    [self unLock];
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
            [self.sessionDelegate handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:taskIdentifier resumeData:nil];
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (BOOL)removeDownloadTaskFromWaitingDownloadArrayByUrlPath:(NSString *)url {
    [self lock];
    NSInteger foundIdx = [self.waitingDownloadArray indexOfObjectPassingTest:
                          ^BOOL(NSDictionary<NSString *,NSObject *> * _Nonnull waitingDownloadDict, NSUInteger idx, BOOL * _Nonnull stop) {
                              NSString *waitingUrlPath = (NSString *)waitingDownloadDict[OSDownloadURLKey];
                              return [url isKindOfClass:[NSString class]] && [url isEqualToString:waitingUrlPath];
                          }];
    if (foundIdx != NSNotFound) {
        [self.waitingDownloadArray removeObjectAtIndex:foundIdx];
        return YES;
    }
    [self unLock];
    return NO;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - download status
////////////////////////////////////////////////////////////////////////

- (BOOL)isDownloading:(NSString *)urlPath {
    
    __block BOOL isDownloading = NO;
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier != NSNotFound) {
        OSDownloadItem *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
        if (downloadItem) {
            isDownloading = YES;
            NSArray *tasks = self.downloadTasks;
            NSUInteger taskIdxInDownloadTasks = [self.downloadTasks indexOfObjectPassingTest:^BOOL(NSURLSessionDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return obj.taskIdentifier == taskIdentifier;
            }];
            if (taskIdxInDownloadTasks != NSNotFound) {
                NSURLSessionDownloadTask *downloadTask = [tasks objectAtIndex:taskIdxInDownloadTasks];
                if (downloadItem.sessionDownloadTask != downloadTask) {
                    downloadItem.sessionDownloadTask  = downloadTask;
                }
//                if (downloadTask.state != NSURLSessionTaskStateRunning) {
//                    isDownloading = NO;
//                }
            }
        }
    }
    
    return isDownloading;
}

- (BOOL)isWaiting:(NSString *)urlPath {
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
    
    return isWaiting;
}

- (BOOL)hasActiveDownloads {
    BOOL isHasActive = NO;
    if (self.activeDownloadsDictionary.count || self.waitingDownloadArray.count) {
        isHasActive = YES;
    }
    return isHasActive;
}



- (void)checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded {
    
    if (self.maxConcurrentDownloads == NSIntegerMax || self.activeDownloadsDictionary.count < self.maxConcurrentDownloads) {
        // 判断等待中是否有任务等待
        if (self.waitingDownloadArray.count) {
            // 取出waitingDownloadArray中最前面的下载
            NSDictionary *waitingDownTaskDict = [self.waitingDownloadArray firstObject];
            NSData *resumeData = waitingDownTaskDict[OSDownloadResumeDataKey];
            [self downloadWithURL:waitingDownTaskDict[OSDownloadURLKey] resumeData:resumeData];
            // 取出前面的下载后会添加到activeDownloadsDictionary，从waitingDownloadArray中移除
            [self.waitingDownloadArray removeObjectAtIndex:0];
            [self.sessionDelegate _startDownloadTaskFromTheWaitingQueue:waitingDownTaskDict[OSDownloadURLKey]];
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - download progress
////////////////////////////////////////////////////////////////////////


- (OSDownloadProgress *)getDownloadProgressByURL:(NSString *)urlPath {
    OSDownloadProgress *downloadProgress = nil;
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier != NSNotFound) {
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
    
    [self.sessionDelegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    
}

/// 当接收到下载数据的时候调用,监听文件下载的进度 该方法会被调用多次
/// totalBytesWritten:已经写入到文件中的数据大小
/// totalBytesExpectedToWrite:目前文件的总大小
/// bytesWritten:本次下载的文件数据大小
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    [self.sessionDelegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

/// 恢复下载的时候调用该方法
/// fileOffset:恢复之后，要从文件的什么地方开发下载
/// expectedTotalBytes：该文件数据的预计总大小
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    [self.sessionDelegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionTaskDelegate
////////////////////////////////////////////////////////////////////////

/// 当请求完成之后调用该方法
/// 不论是请求成功还是请求失败都调用该方法，如果请求失败，那么error对象有值，否则那么error对象为空
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self.sessionDelegate URLSession:session task:task didCompleteWithError:error];
}


/// SSL / TLS 验证
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    [self.sessionDelegate URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDelegate
////////////////////////////////////////////////////////////////////////

/// 后台任务完成时调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    [self.sessionDelegate URLSessionDidFinishEventsForBackgroundURLSession:session];
}

/// 当不再需要连接调用Session的invalidateAndCancel直接关闭，或者调用finishTasksAndInvalidate等待当前Task结束后关闭
/// 此时此方法会收到回调
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    [self.sessionDelegate URLSession:session didBecomeInvalidWithError:error];
}


// 创建并配置backgroundConfiguration
- (NSURLSessionConfiguration *)createBackgroundSessionConfig {
    // 创建后台会话配置对象
    NSURLSessionConfiguration *backgroundConfiguration = nil;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundDownloadSessionIdentifier];
    } else {
        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:kBackgroundDownloadSessionIdentifier];
    }
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
    return backgroundConfiguration;
}



////////////////////////////////////////////////////////////////////////
#pragma mark - Private methods
////////////////////////////////////////////////////////////////////////

/// 通过downloadToken获取下载任务的TaskIdentifier
- (NSInteger)getDownloadTaskIdentifierByURL:(nonnull NSString *)urlPath {
    NSInteger taskIdentifier = NSNotFound;
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

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)dealloc {
    
    [self.backgroundSeesion finishTasksAndInvalidate];
}


- (NSString *)description {
    NSMutableDictionary *descriptionDict = [NSMutableDictionary dictionary];
    [descriptionDict setObject:self.activeDownloadsDictionary forKey:@"activeDownloadsDictionary"];
    [descriptionDict setObject:self.waitingDownloadArray forKey:@"waitingDownloadsArray"];
    [descriptionDict setObject:@(self.maxConcurrentDownloads) forKey:@"maxConcurrentDownloads"];
    
    NSString *descriptionString = [NSString stringWithFormat:@"%@", descriptionDict];
    
    return descriptionString;
}


- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {

    if (maxConcurrentDownloads > _maxConcurrentDownloads
        && maxConcurrentDownloads < NSIntegerMax) {
        _maxConcurrentDownloads = maxConcurrentDownloads;
        [self checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
    }
}

- (NSInteger)maxConcurrentDownloads {
    return _maxConcurrentDownloads ?: NSIntegerMax;
}

- (NSOperationQueue *)backgroundSeesionQueue {
    if (!_backgroundSeesionQueue) {
        _backgroundSeesionQueue = [NSOperationQueue new];
        _backgroundSeesionQueue.maxConcurrentOperationCount = 1;
        _backgroundSeesionQueue.name = @"com.sey.FileDownloaderQueue";
    }
    return _backgroundSeesionQueue;
}

- (NSMutableDictionary<NSNumber *,id<OSDownloadItemProtocol>> *)activeDownloadsDictionary {
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

- (void)lock {
//    [_lock_ lock];
}

- (void)unLock {
//    [_lock_ unlock];
}

@end

