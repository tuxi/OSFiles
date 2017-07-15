//
//  OSDownloaderSessionDataTaskPrivateDelegate.m
//  FileDownloader
//
//  Created by Ossey on 2017/7/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloaderSessionDataTaskPrivateDelegate.h"

@implementation OSDownloaderSessionDataTaskPrivateDelegate


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

////////////////////////////////////////////////////////////////////////
#pragma mark - NSURLSessionDataDelegate
////////////////////////////////////////////////////////////////////////

/// 接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    id<OSDownloadItemProtocol> downloadItem = [self.downloader getDownloadItemByTask:dataTask];
    
    // 打开流
    [downloadItem.outputStream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSURL *cacheURL = [self _getFinalLocalFileURLWithRemoteURL:dataTask.currentRequest.URL];
    long long cacheFileSize = [self.downloader getCacheFileSizeWithPath:cacheURL.path];
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + cacheFileSize;
//    downloadItem.expectedFileTotalSize = totalLength;
    downloadItem.progressObj.expectedFileTotalSize = totalLength;
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/// 接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    id<OSDownloadItemProtocol> downloadItem = [self.downloader getDownloadItemByTask:dataTask];
    // 下载进度
    NSURL *cacheURL = [self _getFinalLocalFileURLWithRemoteURL:dataTask.currentRequest.URL];
    long long cacheFileSize = [self.downloader getCacheFileSizeWithPath:cacheURL.path];
//    NSUInteger receivedSize = cacheFileSize;
//    NSUInteger expectedSize = downloadItem.expectedFileTotalSize;
    NSUInteger expectedSize = downloadItem.progressObj.expectedFileTotalSize;
//    CGFloat progress = 1.0 * receivedSize / expectedSize;
    // 写入数据
    [downloadItem.outputStream write:data.bytes maxLength:data.length];
    if (downloadItem) {
        if (!downloadItem.progressObj.downloadStartDate) {
            downloadItem.progressObj.downloadStartDate = [NSDate date];
            downloadItem.progressObj.bytesPerSecondSpeed = 0;
        }
//        downloadItem.receivedFileSize = cacheFileSize;
        downloadItem.progressObj.receivedFileSize = cacheFileSize;
//        downloadItem.expectedFileTotalSize = expectedSize;
        downloadItem.progressObj.expectedFileTotalSize = expectedSize;
        NSString *taskDescription = [dataTask.taskDescription copy];
        [self _progressChangeWithURL:taskDescription];
    }
    
    
}

/// 请求完毕（成功|失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    id<OSDownloadItemProtocol> downloadItem = [self.downloader getDownloadItemByTask:(NSURLSessionDataTask *)task];
    if (!downloadItem) {
        [self handleDownloadFailureWithError:error downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:nil];
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
                [self handleDownloadSuccessWithDownloadItem:downloadItem taskIdentifier:task.taskIdentifier];
            } else {
                NSError *finalError = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil];
                [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:nil];
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
            [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:nil];
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
        [self handleDownloadFailureWithError:finalError downloadItem:downloadItem taskIdentifier:task.taskIdentifier resumeData:nil];
    }
    
    // 关闭流
    [downloadItem.outputStream close];
    downloadItem.outputStream = nil;
}

@end
