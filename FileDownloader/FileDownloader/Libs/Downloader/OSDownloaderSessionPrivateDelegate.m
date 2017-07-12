//
//  OSDownloaderSessionPrivateDelegate.m
//  FileDownloader
//
//  Created by Ossey on 2017/7/9.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloaderSessionPrivateDelegate.h"
#import "OSDownloadItem.h"
#import "OSDownloader.h"

@interface OSDownloaderSessionPrivateDelegate ()

@property (nonatomic, weak) OSDownloader *downloader;

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
    if ((aHttpStatusCode >= 200) && (aHttpStatusCode < 300))
    {
        anIsCorrectFlag = YES;
    }
    return anIsCorrectFlag;
}

/// 获取下载的文件默认存储的的位置，若代理未实现时则使用此默认的
- (NSURL *)getDefaultLocalFilePathWithRemoteURL:(NSURL *)remoteURL {
    NSURL *localFileURL = [[[self class] getDefaultLocalFolderPath] URLByAppendingPathComponent:remoteURL.lastPathComponent isDirectory:NO];
    return localFileURL;
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

/// 即将开始下载时调用
- (void)_anDownloadTaskWillBegin {
    // 有新的下载任务时重置下载进度
    [self.downloader resetProgressIfNoActiveDownloadsRunning];
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
#pragma mark - download Handler
////////////////////////////////////////////////////////////////////////


/// 下载成功并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadItem:(OSDownloadItem *)downloadItem
                               taskIdentifier:(NSUInteger)taskIdentifier {
    
    downloadItem.downloadProgress.completedUnitCount = downloadItem.downloadProgress.totalUnitCount;
    [self.downloader.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self _anDownloadTaskDidEnd];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate downloadSuccessnWithDownloadItem:downloadItem];
    });
    [self.downloader checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}


/// 下载取消、失败时回调
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadItem:(OSDownloadItem *)downloadItem
                        taskIdentifier:(NSUInteger)taskIdentifier
                            resumeData:(NSData *)resumeData {
    //    downloadItem.naviteProgress.completedUnitCount = downloadItem.naviteProgress.totalUnitCount;
    [self.downloader.activeDownloadsDictionary removeObjectForKey:@(taskIdentifier)];
    [self _anDownloadTaskDidEnd];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadDelegate downloadFailureWithDownloadItem:downloadItem resumeData:resumeData error:error];
    });
    
    [self.downloader checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded];
}



////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDownloadDelegate
////////////////////////////////////////////////////////////////////////

/// 下载完成之后回调
- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    
    NSString *errorStr = nil;
    
    // 获取当前downloadTask对应的OSDownloadItem
    OSDownloadItem *downloadItem = [self.downloader getDownloadItemByDownloadTask:downloadTask];
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
    OSDownloadItem *downloadItem = [self.downloader getDownloadItemByDownloadTask:downloadTask];
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
    
    OSDownloadItem *downloadItem = [self.downloader getDownloadItemByDownloadTask:downloadTask];
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
    OSDownloadItem *downloadItem = [self.downloader getDownloadItemByDownloadTask:(NSURLSessionDownloadTask *)task];
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
    if (self.downloader.backgroundSessionCompletionHandler) {
        self.downloader.backgroundSessionCompletionHandler();
    }
}

/// 当不再需要连接调用Session的invalidateAndCancel直接关闭，或者调用finishTasksAndInvalidate等待当前Task结束后关闭
/// 此时此方法会收到回调
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DLog(@"Error: URL session did become invalid with error: %@", error);
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

- (void)_pauseWithURL:(NSString *)urlPath resumeData:(NSData *)resumeData {
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadPausedWithURL:resumeData:)]) {
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
            // iOS9及以上resumeData(恢复数据)由系统管理，并在使用NSProgress调用时使用
            //                    aResumeData = nil;
        }
        [self.downloadDelegate downloadPausedWithURL:urlPath resumeData:resumeData];
    }
    
}

- (void)_cancelWithURL:(NSString *)urlPath {
    NSError *cancelError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    if (self.downloadDelegate && [self.downloadDelegate respondsToSelector:@selector(downloadFailureWithDownloadItem:resumeData:error:)]) {
        OSDownloadItem *item = [[OSDownloadItem alloc] initWithURL:urlPath sessionDownloadTask:nil];
        [self.downloadDelegate downloadFailureWithDownloadItem:item resumeData:nil error:cancelError];
    }

}


@end
