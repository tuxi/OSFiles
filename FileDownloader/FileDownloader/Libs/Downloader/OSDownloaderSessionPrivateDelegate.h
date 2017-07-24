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

@interface OSDownloaderSessionPrivateDelegate : NSObject  <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, weak) id<OSDownloaderDelegate> downloadDelegate;
@property (nonatomic, weak) OSDownloader *downloader;


- (instancetype)initWithDownloader:(OSDownloader *)downloader;
/// 取消下载、下载失败时调用
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadItem:(id<OSDownloadOperationProtocol>)downloadItem
                        taskIdentifier:(NSUInteger)taskIdentifier
                            response:(NSURLResponse *)response;
/// 下载成功后调用 并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadItem:(id<OSDownloadOperationProtocol>)downloadItem
                               taskIdentifier:(NSUInteger)taskIdentifier
                                     response:(NSURLResponse *)response;

/// 获取下载后文件最终存放的本地路径,若代理实现了则设置使用代理的，没实现则使用默认设定的LocalURL
- (NSURL *)_getFinalLocalFileURLWithRemoteURL:(NSURL *)remoteURL;

/// 即将开始下载时调用
- (void)_anDownloadTaskWillBeginWithDownloadItem:(id<OSDownloadOperationProtocol>)downloadItem;
/// 已经结束某个任务，不管是否成功都会调用
- (void)_anDownloadTaskDidEndWithDownloadItem:(id<OSDownloadOperationProtocol>)downloadItem;
/// 任务已经添加到等待队列时调用
- (void)_didWaitingDownloadForUrlPath:(NSString *)url;
/// 从等待队列中开始下载一个任务
- (void)_startDownloadTaskFromTheWaitingQueue:(NSString *)url;

/// 收到恢复下载的回调
- (void)_resumeWithURL:(NSString *)urlPath;
/// 收到暂停下载的回调
- (void)_pauseWithURL:(NSString *)urlPath;
/// 进度改变时更新进度
- (void)_progressChangeWithURL:(NSString *)urlPath;
/// 根据服务器响应的HttpStatusCode验证服务器响应状态
- (BOOL)_isVaildHTTPStatusCode:(NSUInteger)httpStatusCode
                           url:(NSString *)urlPath;

@end
