//
//  FileDownloaderSessionPrivateDelegate.h
//  FileDownloader
//
//  Created by Ossey on 2017/7/9.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadProtocol.h"

@class FileDownloader;

@interface FileDownloaderSessionPrivateDelegate : NSObject  <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, weak) id<FileDownloaderDelegate> downloadDelegate;
@property (nonatomic, weak) FileDownloader *downloader;


- (instancetype)initWithDownloader:(FileDownloader *)downloader;
/// 取消下载、下载失败时调用
- (void)handleDownloadFailureWithError:(NSError *)error
                          downloadOperation:(id<FileDownloadOperation>)downloadOperation
                        taskIdentifier:(NSUInteger)taskIdentifier
                            response:(NSURLResponse *)response;
/// 下载成功后调用 并已成功保存到本地
- (void)handleDownloadSuccessWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation
                               taskIdentifier:(NSUInteger)taskIdentifier
                                     response:(NSURLResponse *)response;

/// 即将开始下载时调用
- (void)_anDownloadTaskWillBeginWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation;
/// 已经结束某个任务，不管是否成功都会调用
- (void)_anDownloadTaskDidEndWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation;
/// 任务已经添加到等待队列时调用
- (void)_didWaitingDownloadForUrlPath:(NSString *)url;
/// 从等待队列中开始下载一个任务
- (void)_startDownloadTaskFromTheWaitingQueue:(NSString *)url;
/// 收到暂停下载的回调
- (void)_pauseWithURL:(NSString *)urlPath;
/// 进度改变时更新进度
- (void)_progressChangeWithURL:(NSString *)urlPath;
/// 根据服务器响应的HttpStatusCode验证服务器响应状态
- (BOOL)_isVaildHTTPStatusCode:(NSUInteger)httpStatusCode
                           url:(NSString *)urlPath;

@end
