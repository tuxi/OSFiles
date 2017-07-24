//
//  OSDownloader.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloader.h"
#import "OSDownloaderSessionPrivateDelegate.h"
#import "OSDownloadOperation.h"

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
NSString * const OSDownloaderFolderNameKey = @"OSDownloaderFolder";
static void *ProgressObserverContext = &ProgressObserverContext;



@interface OSDownloader () <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *backgroundSeesion;
@property (nonatomic, strong) NSOperationQueue *backgroundSeesionQueue;
@property (nonatomic, strong) NSURL *downloaderFolderPath;
@property (nonatomic, strong) OSDownloaderSessionPrivateDelegate *sessionDelegate;
@property (nonatomic, strong) NSProgress *totalProgress;

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
        // 创建任务进度管理对象 UnitCount是一个基于UI上的完整任务的单元数
        // 这个方法创建了一个NSProgress实例作为当前实例的子类，以要执行的任务单元总数来初始化
        self.totalProgress = [NSProgress progressWithTotalUnitCount:0];
        // 对任务进度对象的完成比例进行监听:监听progress的fractionCompleted的改变,
        // NSKeyValueObservingOptionInitial观察最初的值（在注册观察服务时会调用一次触发方法）
        // fractionCompleted的返回值是0到1，显示了任务的整体进度。如果当没有子实例的话，fractionCompleted就是简单的完成任务数除以总得任务数。
        [self.totalProgress addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                                options:NSKeyValueObservingOptionInitial
                                context:ProgressObserverContext];
        
        _sessionDelegate = [[OSDownloaderSessionPrivateDelegate alloc] initWithDownloader:self];
        _backgroundSeesion = [NSURLSession sessionWithConfiguration:[self createBackgroundSessionConfig] delegate:self delegateQueue:self.backgroundSeesionQueue];
        _backgroundSeesion.sessionDescription = @"OSDownload_BackgroundSession";
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



- (void)getDownloadTasks:(void (^)(NSArray *downloadTasks))downloadTasksBlock {
    [self.backgroundSeesion getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if (downloadTasksBlock) {
            downloadTasksBlock(downloadTasks);
        }
    }];
}

- (OSDownloadOperation *)getDownloadItemByTask:(NSURLSessionDataTask *)task {
    @synchronized (_activeDownloadsDictionary) {
        OSDownloadOperation *downloadItem = nil;
        downloadItem = [self.activeDownloadsDictionary objectForKey:@(task.taskIdentifier)];
        if (downloadItem) {
            return downloadItem;
        }
        NSString *urlPath = [[task taskDescription] copy];
        if (urlPath) {
            self.totalProgress.totalUnitCount++;

            // 将此totalProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
            [self.totalProgress becomeCurrentWithPendingUnitCount:1];
            
            downloadItem = [[OSDownloadOperation alloc] initWithURL:urlPath sessionDataTask:task];
            // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用,必须在同一个线程
            [self.totalProgress resignCurrent];
            
            // 将下载任务保存到activeDownloadsDictionary中
            [self.activeDownloadsDictionary setObject:downloadItem
                                               forKey:@(task.taskIdentifier)];
            [self initializeDownloadCallBack:downloadItem];
            [self.sessionDelegate _anDownloadTaskWillBeginWithDownloadItem:downloadItem];
        }
        
        return downloadItem;
        
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Download
////////////////////////////////////////////////////////////////////////

- (NSURLSessionDataTask *)downloadTaskWithURLPath:(NSString *)urlPath
                                             progress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                                    completionHandler:(void (^)(NSURLResponse * _Nonnull, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    
    id<OSDownloadOperationProtocol> item = [self downloadWithURL:urlPath];
    item.progressHandler = downloadProgressBlock;
    item.completionHandler = completionHandler;
    return item.sessionTask;
    
}

- (NSURLSessionDataTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                         progress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock
                                completionHandler:(void (^)(NSURLResponse * _Nonnull, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    id<OSDownloadOperationProtocol> item = [self downloadWithRequest:request];
    item.progressHandler = downloadProgressBlock;
    item.completionHandler = completionHandler;
    return item.sessionTask;
}

- (id<OSDownloadOperationProtocol>)downloadWithURL:(NSString *)urlPath {
    NSURL *remoteURL = [NSURL URLWithString:urlPath];
    NSURL *cacheURL = [self.sessionDelegate _getFinalLocalFileURLWithRemoteURL:remoteURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:remoteURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    long long cacheFileSize = [self getCacheFileSizeWithPath:cacheURL.path];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", cacheFileSize];
    [request setValue:range forHTTPHeaderField:@"Range"];
    return [self downloadWithRequest:request];
}

- (id<OSDownloadOperationProtocol>)downloadWithRequest:(NSURLRequest *)request  {
    // 无任务下载时，重置总进度
    [self resetProgressIfNoActiveDownloadsRunning];
    
    NSUInteger taskIdentifier = 0;
    NSURL *remoteURL = request.URL;
    NSString *urlPath = remoteURL.absoluteString;
    if (self.maxConcurrentDownloads == NSIntegerMax || self.activeDownloadsDictionary.count < self.maxConcurrentDownloads) {
        
        @synchronized (_activeDownloadsDictionary) {
            OSDownloadOperation *downloadItem = [self getDownloadItemByURL:urlPath];
            if (!downloadItem) {
                self.totalProgress.totalUnitCount++;
                [self.totalProgress becomeCurrentWithPendingUnitCount:1];
                NSURL *cacheURL = [self.sessionDelegate _getFinalLocalFileURLWithRemoteURL:remoteURL];
                NSOutputStream *stream = [NSOutputStream outputStreamWithURL:cacheURL append:YES];
                NSURLSessionDataTask *dataTask = [self.backgroundSeesion dataTaskWithRequest:request];
                taskIdentifier = dataTask.taskIdentifier;
                dataTask.taskDescription = urlPath;
                downloadItem = [[OSDownloadOperation alloc] initWithURL:urlPath sessionDataTask:dataTask];
                downloadItem.finalLocalFileURL = cacheURL;
                downloadItem.outputStream = stream;
                
                long long cacheFileSize = 0;
                NSString *range = [request valueForHTTPHeaderField:@"Range"];
                if ([range hasPrefix:@"bytes"]) {
                    NSArray *bytes = [range componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
                    if ([bytes count] == 2) {
                        NSString *cacheSize = [bytes objectAtIndex:1];
                        cacheFileSize = [[cacheSize componentsSeparatedByString:@"-"].firstObject longLongValue];
                    }
                }
                
                if (cacheFileSize > 0) {
                    downloadItem.progressObj.resumedFileSizeInBytes = cacheFileSize;
                    downloadItem.progressObj.receivedFileSize = cacheFileSize;
                    downloadItem.progressObj.downloadStartDate = [NSDate date];
                    downloadItem.progressObj.bytesPerSecondSpeed = 0;
                    DLog(@"INFO: Download (id: %@) resumed (offset: %@ bytes, expected: %@ bytes", dataTask.taskDescription, @(cacheFileSize), @(downloadItem.progressObj.expectedFileTotalSize));
                }
                
                
                [self.totalProgress resignCurrent];
            } else {
                DLog(@"INFO: download item exit");
            }
            NSURLSessionDataTask *dataTask = downloadItem.sessionTask;
            // 将下载任务保存到activeDownloadsDictionary中
            [self.activeDownloadsDictionary setObject:downloadItem
                                               forKey:@(dataTask.taskIdentifier)];
            [self initializeDownloadCallBack:downloadItem];
            [self.sessionDelegate _anDownloadTaskWillBeginWithDownloadItem:downloadItem];
            [dataTask resume];
            return downloadItem;
        }
    } else {
        
        @synchronized (_waitingDownloadArray) {
            // 超出同时的最大下载数量时，将新的任务的aResumeData或者aRemoteURL添加到等待下载数组中
            NSMutableDictionary *waitingDownloadDict = [NSMutableDictionary dictionary];
            if (urlPath) {
                [waitingDownloadDict setObject:urlPath forKey:OSDownloadURLKey];
            }
            [self.waitingDownloadArray addObject:waitingDownloadDict];
            [self.sessionDelegate _didWaitingDownloadForUrlPath:urlPath];
        }
    }
    return nil;
}




- (long long)getCacheFileSizeWithPath:(NSString *)url {
    NSDictionary *fileAtt = [[NSFileManager defaultManager] attributesOfItemAtPath:url error:nil];
    return [fileAtt[NSFileSize] longLongValue];
}

/// 通过urlPath恢复下载
- (void)resumeWithURL:(NSString *)urlPath {
    BOOL isDownloading = [self isDownloading:urlPath];
    if (!isDownloading) {
        [self.sessionDelegate _resumeWithURL:urlPath];
    }
}

- (void)initializeDownloadCallBack:(OSDownloadOperation *)downloadItem  {
    
    if (downloadItem) {
        
        NSString *urlPath = [downloadItem.urlPath copy];
        __weak typeof(self) weakSelf = self;
        
        downloadItem.pausingHandler = ^{
            [weakSelf pauseWithURL:urlPath];
        };
        
        downloadItem.cancellationHandler = ^{
            [weakSelf cancelWithURL:urlPath];
        };
        
        downloadItem.resumingHandler = ^{
            [weakSelf resumeWithURL:urlPath];
        };
        
        
    } else {
        DLog(@"Error: No download item");
    }
}


- (void)pauseWithURL:(NSString *)urlPath {
    BOOL isDownloading = [self isDownloading:urlPath];
    if (isDownloading) {
        
        [self pauseWithURL:urlPath completionHandler:^{
            [self.sessionDelegate _pauseWithURL:urlPath];
        }];
        
    }
    
    BOOL isWaiting = [self isWaiting:urlPath];
    if (isWaiting) {
        [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
    }
}

- (void)pauseWithURL:(NSString *)urlPath completionHandler:(void (^)())completion {
    
    // 根据downloadIdentifier获取tashIdentifier
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    
    // 当taskIdentifier!=NSNotFound时有效
    if (taskIdentifier != NSNotFound) {
        [self pauseWithTaskIdentifier:taskIdentifier completionHandler:completion];
    } else {
        [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
    }
    
}


- (void)pauseWithTaskIdentifier:(NSUInteger)taskIdentifier completionHandler:(void (^)())completion {
    
    // 从正在下载的集合中根据taskIdentifier获取到OSDownloadOperation
    OSDownloadOperation *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadItem) {
        NSURLSessionDataTask *downloadTask = (NSURLSessionDataTask *)downloadItem.sessionTask;
        if (downloadTask) {
            if (completion) {
                // 有时suspend无效
                // [downloadTask suspend];
                [downloadTask cancel];
            } else {
                [downloadTask cancel];
            }
            completion(nil);
            // 此时会调用NSURLSessionTaskDelegate 的 URLSession:task:didCompleteWithError:
        } else {
            DLog(@"INFO: NSURLSessionDownloadTask cancelled (task not found): %@", downloadItem.urlPath);
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            // 当downloadTask不存在时执行下载失败的回调
            [self.sessionDelegate handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:taskIdentifier response:nil];
        }
    }
}

- (void)cancelWithURL:(NSString *)urlPath {
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier != NSNotFound) {
        [self cancelWithTaskIdentifier:taskIdentifier];
    } else {
        BOOL res = [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
        if (res) {
            
            NSError *cancelError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            OSDownloadOperation *item = [[OSDownloadOperation alloc] initWithURL:urlPath sessionDataTask:nil];
            [self.sessionDelegate handleDownloadFailureWithError:cancelError downloadItem:item taskIdentifier:NSNotFound response:nil];
        }
    }
}

- (void)cancelWithTaskIdentifier:(NSUInteger)taskIdentifier {
    OSDownloadOperation *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadItem) {
        NSURLSessionTask *dataTask = downloadItem.sessionTask;
        if (dataTask) {
            [dataTask cancel];
            // NSURLSessionTaskDelegate method is called
            // URLSession:task:didCompleteWithError:
        } else {
            DLog(@"INFO: NSURLSessionDownloadTask cancelled (task not found): %@", downloadItem.urlPath);
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            [self.sessionDelegate handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:taskIdentifier response:nil];
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (BOOL)removeDownloadTaskFromWaitingDownloadArrayByUrlPath:(NSString *)url {
    @synchronized (_waitingDownloadArray) {
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
}

////////////////////////////////////////////////////////////////////////
#pragma mark - download status
////////////////////////////////////////////////////////////////////////

- (BOOL)isDownloading:(NSString *)urlPath {
    
    @synchronized (_activeDownloadsDictionary) {
        __block BOOL isDownloading = NO;
        NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
        if (taskIdentifier != NSNotFound) {
            OSDownloadOperation *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
            if (downloadItem) {
                isDownloading = downloadItem.sessionTask.state == NSURLSessionTaskStateRunning;
            }
        }
        
        return isDownloading;
        
    }
}

- (BOOL)isWaiting:(NSString *)urlPath {
    @synchronized (_waitingDownloadArray) {
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
}

/// 判断该文件是否下载完成
- (BOOL)isCompletionByRemoteUrlPath:(NSString *)url {
    OSDownloadOperation *item = [self getDownloadItemByURL:url];
    NSURL *localURL = [self.sessionDelegate _getFinalLocalFileURLWithRemoteURL:[NSURL URLWithString:url]];
    if (item.progressObj.expectedFileTotalSize && [self getCacheFileSizeWithPath:localURL.path] == item.progressObj.expectedFileTotalSize) {
        return YES;
    }
    return NO;
}

- (BOOL)hasActiveDownloads {
    BOOL isHasActive = NO;
    if (self.activeDownloadsDictionary.count || self.waitingDownloadArray.count) {
        isHasActive = YES;
    }
    return isHasActive;
}



- (void)checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded {
    
    @synchronized (_activeDownloadsDictionary) {
        if (self.maxConcurrentDownloads == NSIntegerMax || self.activeDownloadsDictionary.count < self.maxConcurrentDownloads) {
            if (self.waitingDownloadArray.count) {
                NSDictionary *waitingDownTaskDict = [self.waitingDownloadArray firstObject];
                [self downloadWithURL:waitingDownTaskDict[OSDownloadURLKey]];
                [self.waitingDownloadArray removeObjectAtIndex:0];
                [self.sessionDelegate _startDownloadTaskFromTheWaitingQueue:waitingDownTaskDict[OSDownloadURLKey]];
            }
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
    OSDownloadOperation *downloadItem = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadItem) {
        progressObj = downloadItem.progressObj;
    }
    return progressObj;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    
    if (context == ProgressObserverContext) {
        NSProgress *progress = object;
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadTotalProgressCanceldNotification object:progress];
            });
            
        } else {
            DLog(@"ERR: Invalid keyPath");
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
    
}

/// 如果当前没有正在下载中的就重置进度
- (void)resetProgressIfNoActiveDownloadsRunning {
    BOOL hasActiveDownloadsFlag = [self hasActiveDownloads];
    if (hasActiveDownloadsFlag == NO) {
        @try {
            [self.totalProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
        } @catch (NSException *exception) {
            DLog(@"Error: Repeated removeObserver(keyPath = fractionCompleted)");
        } @finally {
            
        }
        
        self.totalProgress = [NSProgress progressWithTotalUnitCount:0];
        [self.totalProgress addObserver:self
                             forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                                options:NSKeyValueObservingOptionInitial
                                context:ProgressObserverContext];
    }
}



#pragma mark NSURLSessionDataDelegate

/// 接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    [self.sessionDelegate URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

/// 接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.sessionDelegate URLSession:session dataTask:dataTask didReceiveData:data];
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
    /**
     使用backgroundSessionConfiguration，进入后台并不会下载
     在进入前台时会回调- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
     didCompleteWithError:(nullable NSError *)error;
     导致任务下载失败
     解决方法：使用defaultSessionConfiguration
     */
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
    //        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundDownloadSessionIdentifier];
    //    } else {
    //        backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:kBackgroundDownloadSessionIdentifier];
    //    }
    // 同时设置值timeoutIntervalForRequest和timeoutIntervalForResource值NSURLSessionConfiguration，较小的值会受到影响
    // 请求超时时间；默认为60秒
    backgroundConfiguration.timeoutIntervalForRequest = 180;
    // 是否允许蜂窝网络访问（2G/3G/4G）
    backgroundConfiguration.allowsCellularAccess = NO;
    // 限制每次最多连接数；在 iOS 中默认值为4
    // backgroundConfiguration.HTTPMaximumConnectionsPerHost = self.maxConcurrentDownloads;
    // 允许后台任务按系统的最佳时间安排，以获得最佳性能 (仅background session有效)
    // 设置discretionary = YES 后，若iPhone未连接电源则下载没有任何响应，连接电源后立即可以下载
    //    backgroundConfiguration.discretionary = NO;
    
    
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
        OSDownloadOperation *downloadItem = [self.activeDownloadsDictionary objectForKey:identifier];
        if ([downloadItem.urlPath isEqualToString:urlPath]) {
            taskIdentifier = [identifier unsignedIntegerValue];
            break;
        }
    }
    return taskIdentifier;
}


/// 通过downloadToken获取下载任务的downloadItem
- (id<OSDownloadOperationProtocol>)getDownloadItemByURL:(nonnull NSString *)urlPath {
    NSInteger identifier = [self getDownloadTaskIdentifierByURL:urlPath];
    OSDownloadOperation *downloadItem = [self.activeDownloadsDictionary objectForKey:@(identifier)];
    return downloadItem;
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)dealloc {
    
    [self.backgroundSeesion finishTasksAndInvalidate];
    [self.totalProgress removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                               context:ProgressObserverContext];
    
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

- (NSMutableDictionary<NSNumber *,id<OSDownloadOperationProtocol>> *)activeDownloadsDictionary {
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

@end

