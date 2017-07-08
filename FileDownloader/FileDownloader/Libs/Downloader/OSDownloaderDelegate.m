//
//  OSDownloaderDelegate.m
//  FileDownloader
//
//  Created by Ossey on 2017/7/3.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloaderDelegate.h"
#import "UIApplication+ActivityIndicator.h"
#import "OSDownloaderModule.h"
#import "OSDownloadProgress.h"

#define dispatch_main_async_safe(block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}


static void *ProgressObserverContext = &ProgressObserverContext;

NSString * const OSFileDownloadProgressChangeNotification = @"OSFileDownloadProgressChangeNotification";
NSString * const OSFileDownloadSussessNotification = @"OSFileDownloadSussessNotification";
NSString * const OSFileDownloadFailureNotification = @"OSFileDownloadFailureNotification";
NSString * const OSFileDownloadCanceldNotification = @"OSFileDownloadCanceldNotification";

@interface OSDownloaderDelegate ()

@property (nonatomic, strong) NSProgress *progress;

@end

@implementation OSDownloaderDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 创建任务进度管理对象 UnitCount是一个基于UI上的完整任务的单元数
        // 这个方法创建了一个NSProgress实例作为当前实例的子类，以要执行的任务单元总数来初始化
        self.progress = [NSProgress progressWithTotalUnitCount:0];
        // 对任务进度对象的完成比例进行监听:监听progress的fractionCompleted的改变,
        // NSKeyValueObservingOptionInitial观察最初的值（在注册观察服务时会调用一次触发方法）
        // fractionCompleted的返回值是0到1，显示了任务的整体进度。如果当没有子实例的话，fractionCompleted就是简单的完成任务数除以总得任务数。
        [self.progress addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                           options:NSKeyValueObservingOptionInitial
                           context:ProgressObserverContext];
    }
    return self;
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ <OSDownloaderDelegate> ~~~~~~~~~~~~~~~~~~~~~~~



- (void)downloadSuccessnWithDownloadItem:(id<OSDownloadItemProtocol>)downloadItem {
    
    // 根据aIdentifier在downloadItems中查找对应的DownloadItem，更改其下载状态，发送通知
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:downloadItem.urlPath];
    id<OSDownloadFileItemProtocol> fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        DLog(@"INFO: Download success (id: %@)", downloadItem.urlPath);
        
        fileItem = [[OSDownloaderModule sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.status = OSFileDownloadStatusSuccess;
        fileItem.localFileURL = downloadItem.finalLocalFileURL;
        fileItem.MIMEType = downloadItem.MIMEType;
        [[OSDownloaderModule sharedInstance] storedDownloadItems];
    } else {
        DLog(@"Error: Completed download item not found (id: %@)", downloadItem.urlPath);
    }
    dispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadSussessNotification object:downloadItem];
    })
}

- (void)downloadFailureWithDownloadItem:(id<OSDownloadItemProtocol>)downloadItem resumeData:(NSData *)resumeData error:(NSError *)error {
    
    // 根据aIdentifier在downloadItems中查找对应的DownloadItem
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:downloadItem.urlPath];
    id<OSDownloadFileItemProtocol> fileItem = nil;
    if (foundItemIdx != NSNotFound) {
        fileItem = [[OSDownloaderModule sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        fileItem.lastHttpStatusCode = downloadItem.lastHttpStatusCode;
        fileItem.resumeData = resumeData;
        fileItem.downloadError = error;
        fileItem.downloadErrorMessagesStack = downloadItem.errorMessagesStack;
        
        // 更新此下载失败的item的状态
        if (fileItem.status != OSFileDownloadStatusPaused) {
            if (resumeData.length > 0)
            {
                fileItem.status = OSFileDownloadStatusFailure;
            } else if ([error.domain isEqualToString:NSURLErrorDomain]
                       && (error.code == NSURLErrorCancelled))
            {
                fileItem.status = OSFileDownloadStatusCancelled;
            } else
            {
                fileItem.status = OSFileDownloadStatusFailure;
            }
        }
        [[OSDownloaderModule sharedInstance] storedDownloadItems];
        
    }
    dispatch_main_async_safe(^{
        // 发送失败通知
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadFailureNotification object:downloadItem];
    })
}

- (void)downloadTaskWillBegin {
    // 有新的下载任务时重置下载进度
    [self resetProgressIfNoActiveDownloadsRunning];
    [self toggleNetworkActivityIndicatorVisible:YES];
}

- (void)downloadTaskDidEnd {
    [self toggleNetworkActivityIndicatorVisible:NO];
}

- (void)downloadProgressChangeWithURL:(NSString *)url progress:(OSDownloadProgress *)progress {
    
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    id<OSDownloadFileItemProtocol> downloadItem = nil;
    if (foundItemIdx != NSNotFound) {
        downloadItem = [[OSDownloaderModule sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        if (progress) {
            downloadItem.progressObj = progress;
            downloadItem.progressObj.lastLocalizedDescription = downloadItem.progressObj.nativeProgress.localizedDescription;
            downloadItem.progressObj.lastLocalizedAdditionalDescription = downloadItem.progressObj.nativeProgress.localizedAdditionalDescription;
        }
    }
    [[OSDownloaderModule sharedInstance] storedDownloadItems];
    dispatch_main_async_safe(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadProgressChangeNotification object:downloadItem];
    })

}

- (void)downloadPausedWithURL:(NSString *)url resumeData:(NSData *)aResumeData {
    
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    if (foundItemIdx != NSNotFound) {
        DLog(@"INFO: Download paused - id: %@", url);
        
        id<OSDownloadFileItemProtocol> downloadItem = [[OSDownloaderModule sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        downloadItem.status = OSFileDownloadStatusPaused;
        downloadItem.resumeData = aResumeData;
        [[OSDownloaderModule sharedInstance] storedDownloadItems];
    } else {
        DLog(@"Error: Paused download item not found (id: %@)", url);
    }
}

- (void)resumeDownloadWithURL:(NSString *)url {
    
    [[OSDownloaderModule sharedInstance] start:url];
}

- (BOOL)downloadFinalLocalFileURL:(NSURL *)aLocalFileURL isVaildByURL:(NSString *)url {
    
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

- (NSProgress *)usingNaviteProgress {
    return self.progress;
}

/// 有一个任务等待下载时调用
- (void)downloadDidWaitingWithUrlPath:(NSString *)url progress:(OSDownloadProgress *)progress {
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    id<OSDownloadFileItemProtocol> downloadItem = nil;
    if (foundItemIdx != NSNotFound) {
        downloadItem = [[OSDownloaderModule sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        downloadItem.status = OSFileDownloadStatusWaiting;
        if (progress) {
            downloadItem.progressObj = progress;
            downloadItem.progressObj.lastLocalizedDescription = downloadItem.progressObj.nativeProgress.localizedDescription;
            downloadItem.progressObj.lastLocalizedAdditionalDescription = downloadItem.progressObj.nativeProgress.localizedAdditionalDescription;
        }
    }
}

/// 从等待队列中开始下载一个任务
- (void)downloadStartFromWaitingQueueWithURLpath:(NSString *)url progress:(OSDownloadProgress *)progress {
    NSUInteger foundItemIdx = [self foundItemIndxInDownloadItemsByURL:url];
    
    id<OSDownloadFileItemProtocol> downloadItem = nil;
    if (foundItemIdx != NSNotFound) {
        downloadItem = [[OSDownloaderModule sharedInstance].downloadItems objectAtIndex:foundItemIdx];
        if (progress) {
            downloadItem.progressObj = progress;
            downloadItem.progressObj.lastLocalizedDescription = downloadItem.progressObj.nativeProgress.localizedDescription;
            downloadItem.progressObj.lastLocalizedAdditionalDescription = downloadItem.progressObj.nativeProgress.localizedAdditionalDescription;
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Other
////////////////////////////////////////////////////////////////////////

// 查找数组中第一个符合条件的对象（代码块过滤），返回对应索引
// 查找urlPath在downloadItems中对应的OSDownloadItem的索引
- (NSUInteger)foundItemIndxInDownloadItemsByURL:(NSString *)urlPath {
    if (!urlPath.length) {
        return NSNotFound;
    }
    return [[OSDownloaderModule sharedInstance].downloadItems indexOfObjectPassingTest:
            ^BOOL(id<OSDownloadFileItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                return [urlPath isEqualToString:obj.urlPath];
            }];
}


- (void)toggleNetworkActivityIndicatorVisible:(BOOL)visible {
    if (visible) {
        [[UIApplication sharedApplication] retainNetworkActivityIndicator];
    } else {
        [[UIApplication sharedApplication] releaseNetworkActivityIndicator];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (context == ProgressObserverContext) {
        // 取出当前的progress
        NSProgress *progress = object;
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))]) {
            dispatch_main_async_safe(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:OSFileDownloadProgressChangeNotification object:progress];
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
    BOOL hasActiveDownloadsFlag = [[OSDownloaderModule sharedInstance].downloader hasActiveDownloads];
    if (hasActiveDownloadsFlag == NO) {
        @try {
            [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
        } @catch (NSException *exception) {
            DLog(@"Error: Repeated removeObserver(keyPath = fractionCompleted)");
        } @finally {
            
        }
        
        self.progress = [NSProgress progressWithTotalUnitCount:0];
        [self.progress addObserver:self
                        forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                           options:NSKeyValueObservingOptionInitial
                           context:ProgressObserverContext];
    }
}


- (void)dealloc {
    
    [self.progress removeObserver:self
                       forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                          context:ProgressObserverContext];
}


@end
