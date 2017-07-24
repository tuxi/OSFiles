//
//  OSDownloaderSessionPrivateDelegate.m
//  FileDownloader
//
//  Created by Ossey on 2017/7/9.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloaderSessionPrivateDelegate.h"
#import "OSDownloadOperation.h"
#import "OSDownloader.h"

@interface OSDownloaderSessionPrivateDelegate ()

@end

@implementation OSDownloaderSessionPrivateDelegate

- (instancetype)initWithDownloader:(OSDownloader *)downloader {
    if (self = [super init]) {
        _downloader = downloader;
    }
    return self;
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

/// 获取下载的文件默认存储的的位置，若代理未实现时则使用此默认的
- (NSURL *)getDefaultLocalFilePathWithRemoteURL:(NSURL *)remoteURL {
    NSURL *localFileURL = [[[self class] getDefaultLocalFolderPath] URLByAppendingPathComponent:remoteURL.lastPathComponent isDirectory:NO];
    return localFileURL;
}


/// 即将开始下载时调用
- (void)_anDownloadTaskWillBeginWithDownloadItem:(id<OSDownloadOperationProtocol>)downloadItem {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadTaskWillBeginWithDownloadItem:)]) {
        [self.downloadDelegate downloadTaskWillBeginWithDownloadItem:downloadItem];
    }
}

/// 已经结束某个任务，不管是否成功都会调用
- (void)_anDownloadTaskDidEndWithDownloadItem:(id<OSDownloadOperationProtocol>)downloadItem {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadTaskDidEndWithDownloadItem:)]) {
        [self.downloadDelegate downloadTaskDidEndWithDownloadItem:downloadItem];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - download Handler
////////////////////////////////////////////////////////////////////////


/// 下载成功并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadItem:(OSDownloadOperation *)downloadItem
                               taskIdentifier:(NSUInteger)taskIdentifier
                                     response:(NSURLResponse *)response {
    
    downloadItem.progressObj.nativeProgress.completedUnitCount = downloadItem.progressObj.nativeProgress.totalUnitCount;
    if (downloadItem.completionHandler) {
        downloadItem.completionHandler(response, downloadItem.finalLocalFileURL, nil);
    }
    [self.downloader.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self _anDownloadTaskDidEndWithDownloadItem:downloadItem];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate downloadSuccessnWithDownloadItem:downloadItem];
    });
    [self.downloader checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}


/// 下载取消、失败时回调
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadItem:(OSDownloadOperation *)downloadItem
                        taskIdentifier:(NSUInteger)taskIdentifier
                              response:(NSURLResponse *)response {
    downloadItem.progressObj.nativeProgress.completedUnitCount = downloadItem.progressObj.nativeProgress.totalUnitCount;
    if (downloadItem.completionHandler) {
        downloadItem.completionHandler(response, nil, error);
    }
    [self.downloader.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self _anDownloadTaskDidEndWithDownloadItem:downloadItem];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate downloadFailureWithDownloadItem:downloadItem error:error];
    });
    
    [self.downloader checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}



////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


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



/// 进度改变时更新进度
- (void)_progressChangeWithURL:(NSString *)urlPath {
    
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadProgressChangeWithURL:progress:)]) {
        if (urlPath) {
            OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:urlPath];
            [self.downloadDelegate downloadProgressChangeWithURL:urlPath progress:progress];
        }
        
    }
    
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

////////////////////////////////////////////////////////////////////////
#pragma mark - Private delegate methods
////////////////////////////////////////////////////////////////////////

/// 有一个任务等待下载时调用
- (void)_didWaitingDownloadForUrlPath:(NSString *)url {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadDidWaitingWithURLPath:progress:)]) {
        OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:url];
        [self.downloadDelegate downloadDidWaitingWithURLPath:url progress:progress];
    }
}

/// 从等待队列中开始下载一个任务
- (void)_startDownloadTaskFromTheWaitingQueue:(NSString *)url {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadStartFromWaitingQueueWithURLpath:progress:)]) {
        OSDownloadProgress *progress = [self.downloader getDownloadProgressByURL:url];
        [self.downloadDelegate downloadStartFromWaitingQueueWithURLpath:url progress:progress];
    }
}

/// 通过urlPath恢复下载
- (void)_resumeWithURL:(NSString *)urlPath {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadResumeDownloadWithURL:)]) {
        [self.downloadDelegate downloadResumeDownloadWithURL:urlPath];
    } else {
        DLog(@"Error: Resume action called without implementation");
    }
}

- (void)_pauseWithURL:(NSString *)urlPath {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadPausedWithURL:)]) {
        [self.downloadDelegate downloadPausedWithURL:urlPath];
    }
    
}

- (void)_cancelWithURL:(NSString *)urlPath {
    NSError *cancelError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadFailureWithDownloadItem:error:)]) {
        OSDownloadOperation *item = [[OSDownloadOperation alloc] initWithURL:urlPath sessionDataTask:nil];
        [self.downloadDelegate downloadFailureWithDownloadItem:item error:cancelError];
    }
    
}


/// 默认缓存下载文件的本地文件夹
+ (NSURL *)getDefaultLocalFolderPath {
    NSURL *fileDownloadDirectoryURL = nil;
    NSError *anError = nil;
    NSArray *documentDirectoryURLsArray = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectoryURL = [documentDirectoryURLsArray firstObject];
    if (documentsDirectoryURL) {
        fileDownloadDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:OSDownloaderFolderNameKey isDirectory:YES];
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
#pragma mark - NSURLSessionDataDelegate
////////////////////////////////////////////////////////////////////////

/// 接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    id<OSDownloadOperationProtocol> downloadItem = [self.downloader getDownloadItemByTask:dataTask];
    
    // 打开流
    [downloadItem.outputStream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSURL *cacheURL = [self _getFinalLocalFileURLWithRemoteURL:dataTask.currentRequest.URL];
    long long cacheFileSize = [self.downloader getCacheFileSizeWithPath:cacheURL.path];
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + cacheFileSize;
    downloadItem.progressObj.expectedFileTotalSize = totalLength;
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/// 接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    id<OSDownloadOperationProtocol> downloadItem = [self.downloader getDownloadItemByTask:dataTask];
    [downloadItem.outputStream write:data.bytes maxLength:data.length];
    if (downloadItem) {
        if (!downloadItem.progressObj.downloadStartDate) {
            downloadItem.progressObj.downloadStartDate = [NSDate date];
            downloadItem.progressObj.bytesPerSecondSpeed = 0;
        }
        downloadItem.progressObj.receivedFileSize += data.length;
        NSString *taskDescription = [dataTask.taskDescription copy];
        [self _progressChangeWithURL:taskDescription];
    }
    
    
}

/// 请求完毕（成功|失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    id<OSDownloadOperationProtocol> downloadItem = [self.downloader getDownloadItemByTask:(NSURLSessionDataTask *)task];
    if (!downloadItem) {
        [self handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:task.taskIdentifier response:task.response];
        return;
    };
    NSHTTPURLResponse *aHttpResponse = (NSHTTPURLResponse *)task.response;
    NSInteger httpStatusCode = aHttpResponse.statusCode;
    downloadItem.lastHttpStatusCode = httpStatusCode;
    downloadItem.MIMEType = task.response.MIMEType;
    if (error == nil && [self.downloader isCompletionByRemoteUrlPath:downloadItem.urlPath]) {
        // 下载完成
        BOOL httpStatusCodeIsCorrectFlag = [self _isVaildHTTPStatusCode:httpStatusCode url:downloadItem.urlPath];
        if (httpStatusCodeIsCorrectFlag == YES) {
            NSURL *finalLocalFileURL = downloadItem.finalLocalFileURL;
            if (finalLocalFileURL) {
                
                [self handleDownloadSuccessWithDownloadItem:downloadItem taskIdentifier:task.taskIdentifier response:task.response];
            } else {
                NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil];
                [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier response:task.response];
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
            if (downloadItem.completionHandler) {
                downloadItem.completionHandler(task.response, nil, finalError);
            }
            [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier response:task.response];
        }
    } else if (error){
        // 下载失败
        NSString *errorString = [NSString stringWithFormat:@"Invalid http status code: %@", @(httpStatusCode)];
        NSMutableArray<NSString *> *errorMessagesStackArray = [downloadItem.errorMessagesStack mutableCopy];
        if (errorMessagesStackArray == nil) {
            errorMessagesStackArray = [NSMutableArray array];
        }
        [errorMessagesStackArray insertObject:errorString atIndex:0];
        [downloadItem setErrorMessagesStack:errorMessagesStackArray];
        
        NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
        [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier response:task.response];
    }
    
    // 关闭流
    [downloadItem.outputStream close];
    downloadItem.outputStream = nil;
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
