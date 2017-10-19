//
//  FileDownloaderDelegate.m
//  FileDownloader
//
//  Created by Ossey on 2017/7/3.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FileDownloaderDelegate.h"
#import "UIApplication+ActivityIndicator.h"
#import "FileDownloaderManager.h"
#import "FileDownloadProgress.h"
#import "FileDownloadConst.h"
#import "FileDownloadOperation.h"

@implementation FileDownloaderDelegate

////////////////////////////////////////////////////////////////////////
#pragma mark - FileDownloaderDelegate
////////////////////////////////////////////////////////////////////////

- (void)downloadSuccessnWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation {
    
    // 根据aIdentifier在downloadOperation中查找对应的FileDownloadOperation，更改其下载状态，发送通知
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:downloadOperation.urlPath];
    FileItem *fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        DLog(@"INFO: Download success (id: %@)", downloadOperation.urlPath);
        
        fileItem = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.status = FileDownloadStatusSuccess;
        fileItem.MIMEType = downloadOperation.MIMEType;
        [[FileDownloaderManager sharedInstance] storedDownloadItems];
    } else {
        DLog(@"Error: Completed download item not found (id: %@)", downloadOperation.urlPath);
    }
    
    [[FileDownloaderManager sharedInstance] removeDownloadItemByPackageId:fileItem.fileName];
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadSussessNotification object:fileItem];
    })
}

- (void)downloadFailureWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation
                                  error:(NSError *)error {
    
    // 根据aIdentifier在downloadOperation中查找对应的DownloadItem
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:downloadOperation.urlPath];
    FileItem *fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        fileItem = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.lastHttpStatusCode = downloadOperation.lastHttpStatusCode;
        fileItem.downloadError = error;
        fileItem.errorMessagesStack = downloadOperation.errorMessagesStack;
        // 更新此下载失败的item的状态
        if (fileItem.status != FileDownloadStatusPaused) {
            if ([error.domain isEqualToString:NSURLErrorDomain] &&
                (error.code == NSURLErrorCancelled)) {
                fileItem.status = FileDownloadStatusNotStarted;
            } else {
                fileItem.status = FileDownloadStatusFailure;
            }
        }
        [[FileDownloaderManager sharedInstance] storedDownloadItems];
        
    }
    XYDispatch_main_async_safe(^{
        // 发送失败通知
        [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadFailureNotification object:fileItem];
    })
}

- (void)downloadTaskWillBeginWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation {
    [self toggleNetworkActivityIndicatorVisible:YES];
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:downloadOperation.urlPath];
    FileItem *fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        fileItem = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.status = FileDownloadStatusDownloading;
        fileItem.progressObj = downloadOperation.progressObj;
    }
    [[FileDownloaderManager sharedInstance] storedDownloadItems];
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadStartedNotification object:fileItem];
    })
}

- (void)downloadTaskDidEndWithDownloadOperation:(id<FileDownloadOperation>)downloadItem {
    [self toggleNetworkActivityIndicatorVisible:NO];

}

- (void)downloadProgressChangeWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation  {
    
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:downloadOperation.urlPath];
    
    FileItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        item = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.progressObj = downloadOperation.progressObj;
    }
    [[FileDownloaderManager sharedInstance] storedDownloadItems];
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadProgressChangeNotification object:item];
    })
    
}

- (void)downloadPausedWithURL:(NSString *)url {
    
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    FileItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        DLog(@"INFO: Download paused - id: %@", url);
        
        item = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.status = FileDownloadStatusPaused;
        [[FileDownloaderManager sharedInstance] storedDownloadItems];
    } else {
        DLog(@"Error: Paused download item not found (id: %@)", url);
    }
    
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadPausedNotification object:item];
    })
}


- (BOOL)downloadLocalFolderURL:(NSURL *)aLocalFileURL isVaildByURL:(NSString *)url {
    
    // 检测文件大小,项目中有时需要检测下载的文件的类型是否相匹配，这里就仅仅检测文件大小
    // 根据文件的大小判断下载的文件是否有效,比如可以设定当文件超过多少kb就视为无效
    BOOL isValid = YES;
    
    NSError *error = nil;
    NSDictionary *fileAttritubes = [[NSFileManager defaultManager] attributesOfItemAtPath:aLocalFileURL.path error:&error];
    
    if (error) {
        DLog(@"Error: Error on getting file size for item at %@: %@", aLocalFileURL, error.localizedDescription);
        isValid = NO;
    } else {
        unsigned long long fileSize = [fileAttritubes fileSize];
        if (fileSize == 0) {
            isValid = NO;
        }
    }
    return isValid;
}


/// 一个任务进入等待时调用
- (void)downloadDidWaitingWithURLPath:(NSString *)url progress:(FileDownloadProgress *)progress {
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    FileItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        item = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.status = FileDownloadStatusWaiting;
        item.progressObj = progress;
    }
    
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileDownloadWaittingNotification object:item];
    })
}

/// 从等待队列中开始下载一个任务
- (void)downloadStartFromWaitingQueueWithURLPath:(NSString *)url progress:(FileDownloadProgress *)progress {
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    FileItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        item = [[FileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.progressObj = progress;
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

// 查找数组中第一个符合条件的对象（代码块过滤），返回对应索引
// 查找urlPath在downloadItems中对应的FileDownloadOperation的索引
- (NSUInteger)foundItemIndxInDownloadItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    NSUInteger foundIdx =  [[FileDownloaderManager sharedInstance].downloadItems indexOfObjectPassingTest:^BOOL(FileItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [urlPath isEqualToString:obj.urlPath];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    return foundIdx;
}


- (void)toggleNetworkActivityIndicatorVisible:(BOOL)visible {
    if (visible) {
        [[UIApplication sharedApplication] retainNetworkActivityIndicator];
    } else {
        [[UIApplication sharedApplication] releaseNetworkActivityIndicator];
    }
}

@end

