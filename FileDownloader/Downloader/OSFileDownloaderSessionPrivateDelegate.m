//
//  OSFileDownloaderSessionPrivateDelegate.m
//  OSFileDownloader
//
//  Created by alpface on 2017/7/9.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "OSFileDownloaderSessionPrivateDelegate.h"
#import "OSFileDownloader.h"

@implementation OSFileDownloaderSessionPrivateDelegate

- (instancetype)initWithDownloader:(OSFileDownloader *)downloader {
    if (self = [super init]) {
        _downloader = downloader;
    }
    return self;
}

/// 根据服务器响应的HttpStatusCode验证服务器响应状态
- (BOOL)_isVaildHTTPStatusCode:(NSUInteger)httpStatusCode url:(NSString *)urlPath {
    BOOL httpStatusCodeIsCorrectFlag = NO;
    if ([self.downloadDelegate respondsToSelector:@selector(httpStatusCode:isVaildByURL:)]) {
        httpStatusCodeIsCorrectFlag = [self.downloadDelegate httpStatusCode:httpStatusCode isVaildByURL:urlPath];
    } else {
        httpStatusCodeIsCorrectFlag = [[self class] isValidHttpStatusCode:httpStatusCode];
    }
    return httpStatusCodeIsCorrectFlag;
}

+ (BOOL)isValidHttpStatusCode:(NSInteger)aHttpStatusCode {
    BOOL anIsCorrectFlag = NO;
    if ((aHttpStatusCode >= 200) && (aHttpStatusCode < 300)) {
        anIsCorrectFlag = YES;
    } else if (aHttpStatusCode == 416) {
        // HTTP response code: 416是由于读取文件时设置的Range有误造成的,
        // 这个RANGE显然不能超出文件的size
        anIsCorrectFlag = YES;
    }
    return anIsCorrectFlag;
}




/// 开始下载时调用
- (void)_beginDownloadTaskWithDownloadOperation:(id<OSFileDownloadOperation>)downloadOperation {
    downloadOperation.status = OSFileDownloadStatusDownloading;
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(beginDownloadTaskWithDownloadOperation:)]) {
        [self.downloadDelegate beginDownloadTaskWithDownloadOperation:downloadOperation];
    }
}

- (BOOL)_shouldAllowedDownloadTaskWithURL:(NSString *)urlPath localPath:(NSString *)localPath {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(shouldAllowedDownloadTaskWithURL:localPath:)]) {
        return [self.downloadDelegate shouldAllowedDownloadTaskWithURL:urlPath localPath:localPath];
    }
    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - download Handler
////////////////////////////////////////////////////////////////////////


/// 下载成功并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadOperation:(id<OSFileDownloadOperation>)downloadOperation
                               taskIdentifier:(NSUInteger)taskIdentifier
                                     response:(NSURLResponse *)response {
    
    downloadOperation.progressObj.nativeProgress.completedUnitCount = downloadOperation.progressObj.nativeProgress.totalUnitCount;
    if (downloadOperation.completionHandler) {
        downloadOperation.completionHandler(response, downloadOperation.localURL, nil);
    }
    downloadOperation.status = OSFileDownloadStatusSuccess;
    XYDispatch_main_async_safe(^{
      [self.downloadDelegate downloadSuccessnWithDownloadOperation:downloadOperation];
    })
    [self.downloader.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self.downloader checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}


/// 下载取消(或暂停)、失败时回调
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadOperation:(id<OSFileDownloadOperation>)downloadOperation
                        taskIdentifier:(NSUInteger)taskIdentifier
                              response:(NSURLResponse *)response {
    downloadOperation.progressObj.nativeProgress.completedUnitCount = downloadOperation.progressObj.nativeProgress.totalUnitCount;
    XYDispatch_main_async_safe(^{
        // 非用户手动触发暂停时才修改，因为此方法暂停时也会回调
        if (downloadOperation.status != OSFileDownloadStatusPaused) {
            if ([error.domain isEqualToString:NSURLErrorDomain] &&
                (error.code == NSURLErrorCancelled)) {
                downloadOperation.status = OSFileDownloadStatusNotStarted;
            } else {
                downloadOperation.status = OSFileDownloadStatusFailure;
            }
            [self.downloadDelegate downloadFailureWithDownloadOperation:downloadOperation error:error];
        }
        if (downloadOperation.completionHandler) {
            downloadOperation.completionHandler(response, nil, error);
        }
    })
    // 暂停、取消、失败时都要将downloadOperation从activeDownloadsDictionary中移除，
    [self.downloader.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self.downloader checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}



////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


/// 进度改变时更新进度
- (void)_progressChangeWithURL:(NSString *)urlPath {
    
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadProgressChangeWithDownloadOperation:)]) {
        if (urlPath) {
            id<OSFileDownloadOperation> opeartion = [self.downloader getDownloadOperationByURL:urlPath];
            [self.downloadDelegate downloadProgressChangeWithDownloadOperation:opeartion];
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private delegate methods
////////////////////////////////////////////////////////////////////////

/// 一个任务进入等待时调用
- (void)_didWaitingDownloadForUrlPath:(NSString *)url {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadDidWaitingWithURLPath:progress:)]) {
        OSFileDownloadProgress *progress = [self.downloader getDownloadProgressByURL:url];
        [self.downloadDelegate downloadDidWaitingWithURLPath:url progress:progress];
    }
}

/// 从等待队列中开始下载一个任务
- (void)_startDownloadTaskFromTheWaitingQueue:(NSString *)url {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadStartFromWaitingQueueWithURLPath:progress:)]) {
        OSFileDownloadProgress *progress = [self.downloader getDownloadProgressByURL:url];
        [self.downloadDelegate downloadStartFromWaitingQueueWithURLPath:url progress:progress];
    }
}


- (void)_pauseWithURL:(NSString *)urlPath {
    id<OSFileDownloadOperation> downloadOpeartion = [self.downloader getDownloadOperationByURL:urlPath];
    downloadOpeartion.status = OSFileDownloadStatusPaused;
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadPausedWithURL:)]) {
        [self.downloadDelegate downloadPausedWithURL:urlPath];
    }
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDataDelegate
////////////////////////////////////////////////////////////////////////

/// 接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    id<OSFileDownloadOperation> downloadOperation = [self.downloader getDownloadOperationByTask:dataTask];
    
    // 打开流
    [downloadOperation.outputStream open];
    
    // 获得服务器这次请求 返回数据的总长度
    long long cacheFileSize = [self.downloader getCacheFileSizeWithPath:downloadOperation.localURL.path];
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + cacheFileSize;
    downloadOperation.progressObj.expectedFileTotalSize = totalLength;
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/// 接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    id<OSFileDownloadOperation> downloadOperation = [self.downloader getDownloadOperationByTask:dataTask];
    [downloadOperation.outputStream write:data.bytes maxLength:data.length];
    if (downloadOperation) {
        if (!downloadOperation.progressObj.downloadStartDate) {
            downloadOperation.progressObj.downloadStartDate = [NSDate date];
            downloadOperation.progressObj.bytesPerSecondSpeed = 0;
        }
        downloadOperation.progressObj.receivedFileSize += data.length;
        NSString *taskDescription = [dataTask.taskDescription copy];
        [self _progressChangeWithURL:taskDescription];
    }
    
    
}

/// 请求完毕（成功|失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    id<OSFileDownloadOperation> downloadOperation = [self.downloader getDownloadOperationByTask:(NSURLSessionDataTask *)task];
    if (!downloadOperation) {
        [self handleDownloadFailureWithError:error downloadOperation:downloadOperation taskIdentifier:task.taskIdentifier response:task.response];
        return;
    };
    NSHTTPURLResponse *aHttpResponse = (NSHTTPURLResponse *)task.response;
    NSInteger httpStatusCode = 0;
    if (aHttpResponse) {
         httpStatusCode = aHttpResponse.statusCode;
    }
    else {
        httpStatusCode = error.code;
    }
    downloadOperation.lastHttpStatusCode = httpStatusCode;
    downloadOperation.MIMEType = task.response.MIMEType;
    if (error == nil && [self.downloader isCompletionByRemoteUrlPath:downloadOperation.urlPath]) {
        // 下载完成
        BOOL httpStatusCodeIsCorrectFlag = [self _isVaildHTTPStatusCode:httpStatusCode url:downloadOperation.urlPath];
        if (httpStatusCodeIsCorrectFlag == YES) {
            NSURL *finalLocalFileURL = downloadOperation.localURL;
            if (finalLocalFileURL) {
                
                [self handleDownloadSuccessWithDownloadOperation:downloadOperation taskIdentifier:task.taskIdentifier response:task.response];
            } else {
                NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil];
                [self handleDownloadFailureWithError:finalError downloadOperation:downloadOperation taskIdentifier:task.taskIdentifier response:task.response];
            }
        } else {
            NSString *errorString = [NSString stringWithFormat:@"Invalid http status code: %@", @(httpStatusCode)];
            NSMutableArray<NSString *> *errorMessagesStackArray = [downloadOperation.errorMessagesStack mutableCopy];
            if (errorMessagesStackArray == nil) {
                errorMessagesStackArray = [NSMutableArray array];
            }
            [errorMessagesStackArray insertObject:errorString atIndex:0];
            [downloadOperation setErrorMessagesStack:errorMessagesStackArray];
            
            NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
            if (downloadOperation.completionHandler) {
                downloadOperation.completionHandler(task.response, nil, finalError);
            }
            [self handleDownloadFailureWithError:finalError downloadOperation:downloadOperation taskIdentifier:task.taskIdentifier response:task.response];
        }
    } else if (error){
        // 下载失败，注意用户暂停(即为取消时)也会回调这里，但是这里如果是暂停时就不再对私有代理方法进行回调了
        NSString *errorString = error.localizedDescription;
        NSMutableArray<NSString *> *errorMessagesStackArray = [downloadOperation.errorMessagesStack mutableCopy];
        if (errorMessagesStackArray == nil) {
            errorMessagesStackArray = [NSMutableArray array];
        }
        [errorMessagesStackArray insertObject:errorString atIndex:0];
        [downloadOperation setErrorMessagesStack:errorMessagesStackArray];
        [self handleDownloadFailureWithError:error downloadOperation:downloadOperation taskIdentifier:task.taskIdentifier response:task.response];
        
    }
    
    // 关闭流
    [downloadOperation.outputStream close];
    downloadOperation.outputStream = nil;
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
                                         completionHandler:completionHandler];
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
    if (self.downloader.backgroundSessionCompletionHandler) {
        self.downloader.backgroundSessionCompletionHandler();
    }
}

/// 当不再需要连接调用Session的invalidateAndCancel直接关闭，或者调用finishTasksAndInvalidate等待当前Task结束后关闭
/// 此时此方法会收到回调
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DLog(@"Error: URL session did become invalid with error: %@", error);
}

@end
