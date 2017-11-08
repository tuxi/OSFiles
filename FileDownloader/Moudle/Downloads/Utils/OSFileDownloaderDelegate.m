//
//  OSFileDownloaderDelegate.m
//  OSFileDownloader
//
//  Created by Ossey on 2017/7/3.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileDownloaderDelegate.h"
#import "UIApplication+ActivityIndicator.h"
#import "OSFileDownloaderManager.h"
#import "OSFileDownloadProgress.h"
#import "OSFileDownloadConst.h"
#import "OSLoaclNotificationHelper.h"

@implementation OSFileDownloaderDelegate

////////////////////////////////////////////////////////////////////////
#pragma mark - OSFileDownloaderDelegate
////////////////////////////////////////////////////////////////////////

- (void)downloadSuccessnWithDownloadOperation:(id<OSFileDownloadOperation>)downloadOperation {
    
    // 根据aIdentifier在downloadOperation中查找对应的OSFileDownloadOperation，更改其下载状态，发送通知
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:downloadOperation.originalURLString];
    OSRemoteResourceItem *fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        DLog(@"INFO: Download success (id: %@)", downloadOperation.urlPath);
        // 有些下载的文件扩展名，后面会有些乱七八糟的参数，影响我们显示，这里更改下
        NSString *localPath = downloadOperation.localURL.path;
        if ([localPath.pathExtension containsString:@"?"]) {
            NSString *newPath = [localPath componentsSeparatedByString:@"?"].firstObject;
            NSError *moveError = nil;
            [[NSFileManager defaultManager] moveItemAtPath:localPath toPath:newPath error:&moveError];
        }
        fileItem = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.status = OSFileDownloadStatusSuccess;
        fileItem.MIMEType = downloadOperation.MIMEType;
        fileItem.progressObj = downloadOperation.progressObj;
        [[OSFileDownloaderManager sharedInstance] storedDownloadItems];
    } else {
        DLog(@"Error: Completed download item not found (id: %@)", downloadOperation.urlPath);
    }
    
//    [[OSFileDownloaderManager sharedInstance] removeDownloadItemByPackageId:fileItem.fileName];
    XYDispatch_main_async_safe((^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadSussessNotification object:fileItem];
        [self downloadTaskDidEnd];
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            [[OSLoaclNotificationHelper sharedInstance] sendLocalNotificationWithMessage:[NSString stringWithFormat:@"%@-下载成功", fileItem.fileName]];
        }
    }))
}

- (void)downloadFailureWithDownloadOperation:(id<OSFileDownloadOperation>)downloadOperation
                                  error:(NSError *)error {
    
    // 根据aIdentifier在downloadOperation中查找对应的DownloadItem
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:downloadOperation.originalURLString];
    OSRemoteResourceItem *fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        fileItem = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.lastHttpStatusCode = downloadOperation.lastHttpStatusCode;
        fileItem.downloadError = error;
        fileItem.errorMessagesStack = downloadOperation.errorMessagesStack;
        fileItem.progressObj = downloadOperation.progressObj;
        // 更新此下载失败或下载取消的item的状态，如果不是用户暂停的，并且error.code!=NSURLErrorCancelled 那就是下载失败
        if (fileItem.status != OSFileDownloadStatusPaused) {
            if ([error.domain isEqualToString:NSURLErrorDomain] &&
                (error.code == NSURLErrorCancelled)) {
                fileItem.status = OSFileDownloadStatusNotStarted;
            } else {
                fileItem.status = OSFileDownloadStatusFailure;
            }
        }
        [[OSFileDownloaderManager sharedInstance] storedDownloadItems];
        
    }
    XYDispatch_main_async_safe((^{
        // 发送失败通知
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadFailureNotification object:fileItem];
        [self downloadTaskDidEnd];
//        [[OSLoaclNotificationHelper sharedInstance] sendLocalNotificationWithMessage:[NSString stringWithFormat:@"%@-下载失败", fileItem.fileName]];
        
        [[OSFileDownloaderManager sharedInstance] autoDownloadFailure];
    }))
}

- (void)beginDownloadTaskWithDownloadOperation:(id<OSFileDownloadOperation>)downloadOperation {
    [self toggleNetworkActivityIndicatorVisible:YES];
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:downloadOperation.originalURLString];
    OSRemoteResourceItem *fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        fileItem = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.status = OSFileDownloadStatusDownloading;
        fileItem.progressObj = downloadOperation.progressObj;
    }
    [[OSFileDownloaderManager sharedInstance] storedDownloadItems];
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadStartedNotification object:fileItem];
    })
}

- (BOOL)shouldAllowedDownloadTaskWithURL:(NSString *)urlPath localPath:(nonnull NSString *)localPath {
    
    return YES;
}

- (void)downloadProgressChangeWithDownloadOperation:(id<OSFileDownloadOperation>)downloadOperation  {
    
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:downloadOperation.originalURLString];
    
    OSRemoteResourceItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        item = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.progressObj = downloadOperation.progressObj;
    }
    [[OSFileDownloaderManager sharedInstance] storedDownloadItems];
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadProgressChangeNotification object:item];
    })
    
}

- (void)downloadPausedWithURL:(NSString *)url {
    
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:url];
    
    OSRemoteResourceItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        DLog(@"INFO: Download paused - id: %@", url);
        
        item = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.status = OSFileDownloadStatusPaused;
        [[OSFileDownloaderManager sharedInstance] storedDownloadItems];
    } else {
        DLog(@"Error: Paused download item not found (id: %@)", url);
    }
    
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadPausedNotification object:item];
        [self downloadTaskDidEnd];
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
- (void)downloadDidWaitingWithURLPath:(NSString *)url progress:(OSFileDownloadProgress *)progress {
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:url];
    
    OSRemoteResourceItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        item = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.status = OSFileDownloadStatusWaiting;
        item.progressObj = progress;
    }
    
    XYDispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadWaittingNotification object:item];
    })
}

/// 从等待队列中开始下载一个任务
- (void)downloadStartFromWaitingQueueWithURLPath:(NSString *)url progress:(OSFileDownloadProgress *)progress {
    NSUInteger foundItemIdx = [[OSFileDownloaderManager sharedInstance] foundItemIndxInDownloadItemsByURL:url];
    
    OSRemoteResourceItem *item = nil;
    if (foundItemIdx != NSNotFound) {
        item = [[OSFileDownloaderManager sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        item.progressObj = progress;
    }
}

- (void)authenticationChallenge:(NSURLAuthenticationChallenge *)aChallenge
                            url:(NSString *)url
              completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * aCredential))aCompletionHandler {
    //通过调用block，来告诉NSURLSession要不要收到这个证书
    //(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
    //NSURLSessionAuthChallengeDisposition （枚举）如何处理这个证书
    //NSURLCredential 授权
    
    //证书分为好几种：服务器信任的证书、输入密码的证书  。。，所以这里最好判断
    
    if([aChallenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){//服务器信任证书
        
        NSURLCredential *credential = [NSURLCredential credentialForTrust:aChallenge.protectionSpace.serverTrust];//服务器信任证书
        if(aCompletionHandler)
            aCompletionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

/// 一个任务下载结束时调用，当需要隐藏网络活动指示器即将结束的时候调用,不管是否成功都会调用
/// 此时应该在此回调中使用 UIApplication's setNetworkActivityIndicatorVisible: 去设置状态栏网络活动的可见性
- (void)downloadTaskDidEnd {
    [self toggleNetworkActivityIndicatorVisible:NO];
}


- (void)toggleNetworkActivityIndicatorVisible:(BOOL)visible {
    if (visible) {
        [[UIApplication sharedApplication] retainNetworkActivityIndicator];
    } else {
        [[UIApplication sharedApplication] releaseNetworkActivityIndicator];
    }
}

@end

