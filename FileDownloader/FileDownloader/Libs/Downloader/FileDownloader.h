//
//  FileDownloader.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadProgress.h"
#import "FileDownloadProtocol.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const FileDownloaderDefaultFolderNameKey;

@interface FileDownloader : NSObject

/// 同时允许的最大下载数量
@property (nonatomic, assign) NSInteger maxConcurrentDownloads;
/// 完成一个后台任务时回调
@property (nonatomic, copy) void (^backgroundSessionCompletionHandler)();
/// 下载中的任务 key 为 taskIdentifier， value 为 FileDownloadOperation, 下载完成、取消、暂停都会从此字典中移除
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<FileDownloadOperation>> *activeDownloadsDictionary;
/// 等待下载的任务数组 每个元素 字典 为一个等待的任务
@property (nonatomic, strong) NSMutableArray<NSDictionary <NSString *, NSObject *> *> *waitingDownloadArray;
@property (nonatomic, weak) id<FileDownloaderDelegate> downloadDelegate;

- (id<FileDownloadOperation>)getDownloadOperationByTask:(NSURLSessionDataTask *)task;
- (id<FileDownloadOperation>)getDownloadOperationByURL:(nonnull NSString *)urlPath;
- (id<FileDownloadOperation>)getDownloadOperationByFileName:(nonnull NSString *)fileName;

- (long long)getCacheFileSizeWithPath:(NSString *)url;

/// 执行下载任务，若当前下载数量超出maxConcurrentDownloads则添加到等待队列，并且return nil
/// @param urlPath 下载任务的remote url path
/// @param localFolderPath 文件下载时存储到这个文件夹中
/// @param fileName 写入文件的名称
/// @param downloadProgressBlock 进度回调
/// @param completionHandler 下载完成回调，不管成功失败都会回调
/// @return 一个id<FileDownloadOperation> 实例
- (id<FileDownloadOperation>)downloadTaskWithURLPath:(NSString *)urlPath
                                      localFolderPath:(NSString *)localFolderPath
                                            fileName:(NSString *)fileName
                                            progress:(void (^ _Nullable)(NSProgress * _Nullable progress))downloadProgressBlock
                                   completionHandler:(void (^ _Nullable)(NSURLResponse * _Nullable response, NSURL * _Nullable localURL, NSError * _Nullable error))completionHandler;

- (id<FileDownloadOperation>)downloadTaskWithRequest:(NSURLRequest *)request
                                      localFolderPath:(NSString *)localFolderPath
                                            fileName:(NSString *)fileName
                                            progress:(void (^ _Nullable)(NSProgress * _Nullable progress))downloadProgressBlock
                                   completionHandler:(void (^ _Nullable)(NSURLResponse * _Nullable response, NSURL * _Nullable localURL, NSError * _Nullable error))completionHandler;

/// 取消下载, 取消下载后任务不可恢复
/// @param urlPath 下载任务
- (void)cancelWithURL:(NSString *)urlPath;

/// 暂停下载，暂停后任务可恢复
/// @param urlPath 暂停下载任务的urlPath
- (void)pauseWithURL:(NSString *)urlPath;

/// 根据是否urlPath判断正在下载中
/// @param urlPath 下载任务的url
- (BOOL)isDownloading:(NSString *)urlPath;

/// 根据是否urlPath判断在等待中
/// @param urlPath 下载任务的url
- (BOOL)isWaiting:(NSString *)urlPath;

/// 判断该文件是否下载完成
- (BOOL)isCompletionByRemoteUrlPath:(NSString *)url;

/// 当前是否有任务下载
- (BOOL)hasActiveDownloads;

/// 获取下载进度
/// urlPath 当前下载任务的唯一标识符
/// @return 下载进度的信息
- (FileDownloadProgress *)getDownloadProgressByURL:(NSString *)urlPath;

/// 检查当前同时下载的任务数量是否超出最大值maxConcurrentDownloadCount
/// @mark 当当前正在下载的activeDownloadsDictionary任务中小于最大同时下载数量时，
/// @mark 则从等待的waitingDownloadArray中取出第一个开始下载，添加到activeDownloadsDictionary，并从waitingDownloadArray中移除
- (void)checkMaxConcurrentDownloadCountThenDownloadWaitingQueueIfExceeded;

/// 如果当前没有正在下载中的就重置进度
- (void)resetProgressIfNoActiveDownloadsRunning;

- (void)removeAllWaitingDownloadArray;

@end

NS_ASSUME_NONNULL_END
