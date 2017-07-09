//
//  OSDownloaderSessionPrivateDelegate.h
//  FileDownloader
//
//  Created by Ossey on 2017/7/9.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloaderDelegate.h"

@class OSDownloader;

@interface OSDownloaderSessionPrivateDelegate : NSObject  <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>
@property (nonatomic, weak) id<OSDownloaderDelegate> downloadDelegate;

/// 创建NSProgress
- (NSProgress *)progress;

- (instancetype)initWithDownloader:(OSDownloader *)downloader;
/// 取消下载、下载失败时调用
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadItem:(id<OSDownloadItemProtocol>)downloadItem
                        taskIdentifier:(NSUInteger)taskIdentifier
                            resumeData:(NSData *)resumeData;
/// 下载成功后调用 并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadItem:(id<OSDownloadItemProtocol>)downloadItem
                               taskIdentifier:(NSUInteger)taskIdentifier;

/// 即将开始下载时调用
- (void)_anDownloadTaskWillBegin;
/// 已经结束某个任务，不管是否成功都会调用
- (void)_anDownloadTaskDidEnd;
/// 任务已经添加到等待队列时调用
- (void)_didWaitingDownloadForUrlPath:(NSString *)url;
/// 从等待队列中开始下载一个任务
- (void)_startDownloadTaskFromTheWaitingQueue:(NSString *)url;

/// 收到恢复下载的回调
- (void)resumeWithURL:(NSString *)urlPath;
/// 收到暂停下载的回调
- (void)pauseWithURL:(NSString *)urlPath resumeData:(NSData *)resumeData;
@end
