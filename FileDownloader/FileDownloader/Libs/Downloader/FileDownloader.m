//
//  FileDownloader.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FileDownloader.h"
#import "FileDownloaderSessionPrivateDelegate.h"
#import "FileDownloadOperation.h"

// 后台任务的标识符
#define kBackgroundDownloadSessionIdentifier [NSString stringWithFormat:@"%@.FileDownloader", [NSBundle mainBundle].bundleIdentifier]

static NSString * const FileDownloadRemoteURLPathKey = @"FileDownloadRemoteURLPathKey";
static NSString * const FileDownloadLocalFolderURLPathKey = @"FileDownloadLocalFolderURLPathKey";
static NSString * const FileDownloadLocalFileNameKey = @"FileDownloadLocalFileNameKey";
NSString * const FileDownloaderDefaultFolderNameKey = @"FileDownloaderDefaultFolderNameKey";
static void *ProgressObserverContext = &ProgressObserverContext;



@interface FileDownloader () <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *backgroundSeesion;
@property (nonatomic, strong) NSOperationQueue *backgroundSeesionQueue;
@property (nonatomic, strong) FileDownloaderSessionPrivateDelegate *sessionDelegate;
@property (nonatomic, strong) NSProgress *totalProgress;

@end

@implementation FileDownloader

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
        
        _sessionDelegate = [[FileDownloaderSessionPrivateDelegate alloc] initWithDownloader:self];
        _backgroundSeesion = [NSURLSession sessionWithConfiguration:[self createBackgroundSessionConfig] delegate:self delegateQueue:self.backgroundSeesionQueue];
        _backgroundSeesion.sessionDescription = @"FileDownload_BackgroundSession";
    }
    return self;
}


- (void)setDownloadDelegate:(id<FileDownloaderDelegate>)downloadDelegate {
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

- (FileDownloadOperation *)getDownloadOperationByTask:(NSURLSessionDataTask *)task {
    @synchronized (_activeDownloadsDictionary) {
        FileDownloadOperation *downloadOperation = nil;
        downloadOperation = [self.activeDownloadsDictionary objectForKey:@(task.taskIdentifier)];
        if (downloadOperation) {
            return downloadOperation;
        }
        NSString *urlPath = [[task taskDescription] copy];
        if (urlPath) {
            self.totalProgress.totalUnitCount++;
            
            // 将此totalProgress注册为当前线程任务的根进度管理对象，向下分支出一个子任务 比如子任务进度总数为10个单元 即当子任务完成时 父progerss对象进度走1个单元
            [self.totalProgress becomeCurrentWithPendingUnitCount:1];
            
            downloadOperation = [[FileDownloadOperation alloc] initWithURL:urlPath sessionDataTask:task];
            // 注意: 必须和becomeCurrentWithPendingUnitCount成对使用,必须在同一个线程
            [self.totalProgress resignCurrent];
            
            // 将下载任务保存到activeDownloadsDictionary中
            [self.activeDownloadsDictionary setObject:downloadOperation
                                               forKey:@(task.taskIdentifier)];
            [self initializeDownloadCallBack:downloadOperation];
            [self.sessionDelegate _anDownloadTaskWillBeginWithDownloadOperation:downloadOperation];
        }
        
        return downloadOperation;
        
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - Download
////////////////////////////////////////////////////////////////////////

- (id<FileDownloadOperation>)downloadTaskWithURLPath:(NSString *)urlPath
                                     localFolderPath:(NSString *)localFolderPath
                                            fileName:(NSString *)fileName
                                            progress:(void (^ _Nullable)(NSProgress * _Nullable))downloadProgressBlock
                                   completionHandler:(void (^ _Nullable)(NSURLResponse * _Nullable, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    
    id<FileDownloadOperation> item = [self downloadWithURL:urlPath localFolderPath:localFolderPath fileName:fileName];
    item.progressHandler = downloadProgressBlock;
    item.completionHandler = completionHandler;
    return item;
    
}

- (id<FileDownloadOperation>)downloadTaskWithRequest:(NSURLRequest *)request
                                     localFolderPath:(NSString *)localFolderPath
                                            fileName:(NSString *)fileName
                                            progress:(void (^ _Nullable)(NSProgress * _Nullable))downloadProgressBlock
                                   completionHandler:(void (^ _Nullable)(NSURLResponse * _Nullable, NSURL * _Nullable, NSError * _Nullable))completionHandler {
    id<FileDownloadOperation> item = [self downloadWithRequest:request localFolderPath:localFolderPath fileName:fileName];
    item.progressHandler = downloadProgressBlock;
    item.completionHandler = completionHandler;
    return item;
}

- (id<FileDownloadOperation>)downloadWithURL:(NSString *)urlPath localFolderPath:(NSString *)localFolderPath fileName:(NSString *)fileName {
    NSURL *remoteURL = [NSURL URLWithString:urlPath];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:remoteURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:30.0];
    
    return [self downloadWithRequest:request localFolderPath:localFolderPath fileName:fileName];
}

- (id<FileDownloadOperation>)downloadWithRequest:(NSURLRequest *)request localFolderPath:(NSString *)localFolderPath fileName:(NSString *)fileName  {
    
    NSAssert(request, @"Error: request do't is nil");
    
    NSUInteger taskIdentifier = 0;
    NSURL *remoteURL = request.URL;
    NSURL *localFolderURL = [NSURL fileURLWithPath:localFolderPath];
    NSString *urlPath = remoteURL.absoluteString;
    FileDownloadOperation *downloadOperation = [self getDownloadOperationByURL:urlPath];
    // 若已经在下载中，则返回其实例对象
    BOOL isDownloading = [self isDownloading:urlPath];
    if (isDownloading) {
        return downloadOperation;
    }
    
    // 无任务下载时，重置总进度
    [self resetProgressIfNoActiveDownloadsRunning];
    
    if (downloadOperation) {
        /*
         此处为了解决当前request对应的url已存在activeDownloadsDictionary中，但是不符合下面条件时(也就是超出最大可下载数量时)，会导致当前request一直在等待中，无法执行下载，
         进入这里你不必担心会超出最大下载数量，因为在activeDownloadsDictionary中肯定没有超出数量
         (self.maxConcurrentDownloads == NSIntegerMax || self.activeDownloadsDictionary.count < self.maxConcurrentDownloads)
         */
        NSURLSessionDataTask *dataTask = downloadOperation.sessionTask;
        // 将下载任务保存到activeDownloadsDictionary中
        [self.activeDownloadsDictionary setObject:downloadOperation
                                           forKey:@(dataTask.taskIdentifier)];
        [self initializeDownloadCallBack:downloadOperation];
        [self.sessionDelegate _anDownloadTaskWillBeginWithDownloadOperation:downloadOperation];
        [dataTask resume];
        return downloadOperation;
    }
    else {
        if (self.maxConcurrentDownloads == NSIntegerMax || self.activeDownloadsDictionary.count < self.maxConcurrentDownloads) {
            
            @synchronized (_activeDownloadsDictionary) {
                self.totalProgress.totalUnitCount++;
                [self.totalProgress becomeCurrentWithPendingUnitCount:1];
                
                FileDownloadOperation *downloadOperation = [[FileDownloadOperation alloc] initWithURL:urlPath sessionDataTask:nil];
                if (!localFolderURL) {
                    localFolderURL = [self getDefaultLocalFilePathWithRemoteURL:remoteURL];
                }
                downloadOperation.localFolderURL = localFolderURL;
                if (!fileName.length) {
                    fileName = urlPath.lastPathComponent;
                }
                downloadOperation.fileName = fileName;
                NSMutableURLRequest *requestM = request.mutableCopy;
                long long cacheFileSize = [self getCacheFileSizeWithPath:downloadOperation.localURL.path];
                NSString *range = [NSString stringWithFormat:@"bytes=%zd-", cacheFileSize];
                [requestM setValue:range forHTTPHeaderField:@"Range"];
                NSAssert(downloadOperation.localURL, @"Error: local file path do't is nil");
                NSOutputStream *stream = [NSOutputStream outputStreamWithURL:downloadOperation.localURL append:YES];
                NSURLSessionDataTask *dataTask = [self.backgroundSeesion dataTaskWithRequest:requestM];
                taskIdentifier = dataTask.taskIdentifier;
                dataTask.taskDescription = urlPath;
                downloadOperation.sessionTask = dataTask;
                downloadOperation.outputStream = stream;
                
                if (cacheFileSize > 0) {
                    downloadOperation.progressObj.resumedFileSizeInBytes = cacheFileSize;
                    downloadOperation.progressObj.receivedFileSize = cacheFileSize;
                    downloadOperation.progressObj.downloadStartDate = [NSDate date];
                    downloadOperation.progressObj.bytesPerSecondSpeed = 0;
                    DLog(@"INFO: Download (id: %@) resumed (offset: %@ bytes, expected: %@ bytes", dataTask.taskDescription, @(cacheFileSize), @(downloadOperation.progressObj.expectedFileTotalSize));
                }
                
                
                [self.totalProgress resignCurrent];
                // 将下载任务保存到activeDownloadsDictionary中
                [self.activeDownloadsDictionary setObject:downloadOperation
                                                   forKey:@(dataTask.taskIdentifier)];
                [self initializeDownloadCallBack:downloadOperation];
                [self.sessionDelegate _anDownloadTaskWillBeginWithDownloadOperation:downloadOperation];
                [dataTask resume];
                return downloadOperation;
            }
        } else {
            
            @synchronized (_waitingDownloadArray) {
                // 超出同时的最大下载数量时，将新的任务的aResumeData或者aRemoteURL添加到等待下载数组中
                NSMutableDictionary *waitingDownloadDict = [NSMutableDictionary dictionary];
                [waitingDownloadDict setValue:urlPath forKey:FileDownloadRemoteURLPathKey];
                [waitingDownloadDict setValue:localFolderURL.path forKey:FileDownloadLocalFolderURLPathKey];
                [waitingDownloadDict setValue:fileName forKey:FileDownloadLocalFileNameKey];
                [self.waitingDownloadArray addObject:waitingDownloadDict];
                [self.sessionDelegate _didWaitingDownloadForUrlPath:urlPath];
            }
        }
        
    }
    return nil;
}




- (long long)getCacheFileSizeWithPath:(NSString *)url {
    NSDictionary *fileAtt = [[NSFileManager defaultManager] attributesOfItemAtPath:url error:nil];
    return [fileAtt[NSFileSize] longLongValue];
}

/// 通过urlPath恢复下载
- (void)resumeWithURL:(FileDownloadOperation *)downloadOperation {
    BOOL isDownloading = [self isDownloading:downloadOperation.urlPath];
    if (!isDownloading) {
        [self downloadWithURL:downloadOperation.urlPath localFolderPath:downloadOperation.localFolderURL.path fileName:downloadOperation.fileName];
    }
}

- (void)initializeDownloadCallBack:(FileDownloadOperation *)downloadOperation  {
    
    if (!downloadOperation) {
        DLog(@"Error: No download item");
        return;
    }
    
    NSString *urlPath = [downloadOperation.urlPath copy];
    __weak typeof(self) weakSelf = self;
    __weak typeof(downloadOperation) weakOperation = downloadOperation;
    downloadOperation.pausingHandler = ^{
        [weakSelf pauseWithURL:urlPath];
    };
    
    downloadOperation.cancellationHandler = ^{
        [weakSelf cancelWithURL:urlPath];
    };
    
    downloadOperation.resumingHandler = ^{
        [weakSelf resumeWithURL:weakOperation];
    };
}


- (void)pauseWithURL:(NSString *)urlPath {
    BOOL isDownloading = [self isDownloading:urlPath];
    if (isDownloading) {
        
        [self pauseWithURL:urlPath completionHandler:^{
            [self.sessionDelegate _pauseWithURL:urlPath];
        }];
        
    }
    // 当任务没有在(activeDownloadsDictionary)下载中是无法直接取消的
    // 所以这里判断如果在等待中就移除等待中任务，并通知代码
    BOOL isWaiting = [self isWaiting:urlPath];
    if (isWaiting) {
        [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
        [self.sessionDelegate _pauseWithURL:urlPath];
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
    
    // 从正在下载的集合中根据taskIdentifier获取到FileDownloadOperation
    FileDownloadOperation *downloadOperation = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadOperation) {
        NSURLSessionDataTask *downloadTask = (NSURLSessionDataTask *)downloadOperation.sessionTask;
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
            DLog(@"INFO: NSURLSessionDownloadTask cancelled (task not found): %@", downloadOperation.urlPath);
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            // 当downloadTask不存在时执行下载失败的回调
            [self.sessionDelegate handleDownloadFailureWithError:error downloadOperation:downloadOperation taskIdentifier:taskIdentifier response:nil];
        }
    }
}

- (void)cancelWithURL:(NSString *)urlPath {
    // 取消任务时，如果在activeDownloadsDictionary(下载中)，就直接取消
    // 否则就判断是否在waitingDownloadArray(等待中)，若在就移除，并通知代理
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier != NSNotFound) {
        [self cancelWithTaskIdentifier:taskIdentifier];
    } else {
        BOOL res = [self removeDownloadTaskFromWaitingDownloadArrayByUrlPath:urlPath];
        if (res) {
            
            NSError *cancelError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            FileDownloadOperation *item = [[FileDownloadOperation alloc] initWithURL:urlPath sessionDataTask:nil];
            [self.sessionDelegate handleDownloadFailureWithError:cancelError downloadOperation:item taskIdentifier:NSNotFound response:nil];
        }
    }
}

- (void)cancelWithTaskIdentifier:(NSUInteger)taskIdentifier {
    FileDownloadOperation *downloadOperation = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadOperation) {
        NSURLSessionTask *dataTask = downloadOperation.sessionTask;
        if (dataTask) {
            [dataTask cancel];
            // NSURLSessionTaskDelegate method is called
            // URLSession:task:didCompleteWithError:
        } else {
            DLog(@"INFO: NSURLSessionDownloadTask cancelled (task not found): %@", downloadOperation.urlPath);
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            [self.sessionDelegate handleDownloadFailureWithError:error downloadOperation:downloadOperation taskIdentifier:taskIdentifier response:nil];
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
                                  NSString *waitingUrlPath = (NSString *)waitingDownloadDict[FileDownloadRemoteURLPathKey];
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
            FileDownloadOperation *downloadOperation = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
            if (downloadOperation) {
                isDownloading = downloadOperation.sessionTask.state == NSURLSessionTaskStateRunning;
            }
        }
        
        return isDownloading;
        
    }
}

- (BOOL)isWaiting:(NSString *)urlPath {
    @synchronized (_waitingDownloadArray) {
        __block BOOL isWaiting = NO;
        
        [self.waitingDownloadArray enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSObject *> * _Nonnull waitingDownloadDict, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([waitingDownloadDict[FileDownloadRemoteURLPathKey] isKindOfClass:[NSString class]]) {
                NSString *waitingUrlPath = (NSString *)waitingDownloadDict[FileDownloadRemoteURLPathKey];
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
    FileDownloadOperation *item = [self getDownloadOperationByURL:url];
    if (item.progressObj.expectedFileTotalSize && [self getCacheFileSizeWithPath:item.localURL.path] == item.progressObj.expectedFileTotalSize) {
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
                [self downloadWithURL:waitingDownTaskDict[FileDownloadRemoteURLPathKey] localFolderPath:waitingDownTaskDict[FileDownloadLocalFolderURLPathKey] fileName:waitingDownTaskDict[FileDownloadLocalFileNameKey]];
                [self.waitingDownloadArray removeObjectAtIndex:0];
                [self.sessionDelegate _startDownloadTaskFromTheWaitingQueue:waitingDownTaskDict[FileDownloadRemoteURLPathKey]];
            }
        }
    }
}


////////////////////////////////////////////////////////////////////////
#pragma mark - download progress
////////////////////////////////////////////////////////////////////////



- (FileDownloadProgress *)getDownloadProgressByURL:(NSString *)urlPath {
    FileDownloadProgress *downloadProgress = nil;
    NSInteger taskIdentifier = [self getDownloadTaskIdentifierByURL:urlPath];
    if (taskIdentifier != NSNotFound) {
        downloadProgress = [self downloadProgressByTaskIdentifier:taskIdentifier];
    }
    return downloadProgress;
}


/// 根据taskIdentifier 创建 FileDownloadProgress 对象
- (FileDownloadProgress *)downloadProgressByTaskIdentifier:(NSUInteger)taskIdentifier {
    FileDownloadProgress *progressObj = nil;
    FileDownloadOperation *downloadOperation = [self.activeDownloadsDictionary objectForKey:@(taskIdentifier)];
    if (downloadOperation) {
        progressObj = downloadOperation.progressObj;
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
                
                [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadTotalProgressCanceldNotification object:progress];
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
        FileDownloadOperation *downloadOperation = [self.activeDownloadsDictionary objectForKey:identifier];
        if ([downloadOperation.urlPath isEqualToString:urlPath]) {
            taskIdentifier = [identifier unsignedIntegerValue];
            break;
        }
    }
    return taskIdentifier;
}


/// 通过downloadToken获取下载任务的downloadOperation
- (id<FileDownloadOperation>)getDownloadOperationByURL:(nonnull NSString *)urlPath {
    NSInteger identifier = [self getDownloadTaskIdentifierByURL:urlPath];
    FileDownloadOperation *downloadOperation = [self.activeDownloadsDictionary objectForKey:@(identifier)];
    return downloadOperation;
}

/// 获取下载的文件默认存储的的位置，若代理未实现时则使用此默认的
- (NSURL *)getDefaultLocalFilePathWithRemoteURL:(NSURL *)remoteURL {
    NSURL *localFileURL = [[self.class getDefaultLocalFolderPath] URLByAppendingPathComponent:remoteURL.lastPathComponent isDirectory:NO];
    return localFileURL;
}

/// 默认缓存下载文件的本地文件夹
+ (NSURL *)getDefaultLocalFolderPath {
    NSURL *fileDownloadDirectoryURL = nil;
    NSError *anError = nil;
    NSArray *documentDirectoryURLsArray = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = [documentDirectoryURLsArray firstObject];
    if (documentsDirectoryURL) {
        fileDownloadDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:FileDownloaderDefaultFolderNameKey isDirectory:YES];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileDownloadDirectoryURL.path] == NO) {
            BOOL aCreateDirectorySuccess = [[NSFileManager defaultManager] createDirectoryAtPath:fileDownloadDirectoryURL.path withIntermediateDirectories:YES attributes:nil error:&anError];
            if (aCreateDirectorySuccess == NO) {
                DLog(@"Error on create directory: %@", anError);
            } else {
                // 排除备份，即使文件存储在document中，该目录下载的文件也不会被备份到itunes或上传的iCloud中
                BOOL aSetResourceValueSuccess = [fileDownloadDirectoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&anError];
                if (aSetResourceValueSuccess == NO) {
                    DLog(@"Error on set resource value (NSURLIsExcludedFromBackupKey): %@", anError);
                }
            }
        }
        return fileDownloadDirectoryURL;
    }
    return nil;
    
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

- (NSMutableDictionary<NSNumber *,id<FileDownloadOperation>> *)activeDownloadsDictionary {
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

