//
//  FileDownloaderDelegate.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadConst.h"

NS_ASSUME_NONNULL_BEGIN

@class FileDownloadProgress;

@protocol FileDownloadOperation <NSObject>

@required

- (nullable NSOutputStream *)outputStream;
- (void)setOutputStream:(nullable NSOutputStream *)outputStream;

- (FileDownloadProgress *)progressObj;
- (void)setProgressObj:(FileDownloadProgress *)progressObj;

/// 下载的url
- (NSString *)urlPath;
- (void)setUrlPath:(NSString *)urlPath;

/// 下载会话对象 NSURLSessionDownloadTask
- (NSURLSessionDataTask *)sessionTask;
- (void)setSessionTask:(NSURLSessionDataTask *)sessionTask;

/// 下载时发送的错误信息栈 错误信息栈(最新的错误信息初入在第一位)
- (NSArray<NSString *> *)errorMessagesStack;
- (void)setErrorMessagesStack:(NSArray<NSString *> *)errorMessagesStack;

/// 最终文件存储的本地路径
- (NSURL *)localURL;
- (void)setLocalURL:(NSURL *)localURL;

/// 最终文件存储的目录
- (NSURL *)localFolderURL;
- (void)setLocalFolderURL:(NSURL *)localFolderURL;

- (void)setFileName:(NSString *)fileName;
- (NSString *)fileName;

- (FileDownloadStatus)status;
- (void)setStatus:(FileDownloadStatus)status;

- (void)cancel;

@optional
/// 最后的HTTP状态码
- (NSInteger)lastHttpStatusCode;
- (void)setLastHttpStatusCode:(NSInteger)lastHttpStatusCode;

/// 文件的类型
- (NSString *)MIMEType;
- (void)setMIMEType:(NSString *)MIMEType;

@property (nullable, copy) void (^cancellationHandler)(void);
@property (nullable, copy) void (^pausingHandler)(void);
@property (nullable, copy) void (^resumingHandler)(void);
@property (nonatomic, nullable, copy) void (^progressHandler)(NSProgress *progress);
@property (nonatomic, copy) void (^completionHandler)(NSURLResponse *response, NSURL * _Nullable filePath, NSError * _Nullable error);

@end

@protocol FileDownloaderDelegate <NSObject>


/// 下载成功回调
/// 当需要隐藏网络活动指示器，应该在此回调中使用 UIApplication's setNetworkActivityIndicatorVisible: 去设置状态栏网络活动的可见性
/// @param downloadOperation 下载的FileDownloadOperation
- (void)downloadSuccessnWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation;

/// 一个任务下载失败或者取消时调用
/// 当需要隐藏网络活动指示器，应该在此回调中使用 UIApplication's setNetworkActivityIndicatorVisible: 去设置状态栏网络活动的可见性
/// @param downloadOperation 下载的FileDownloadOperation
/// @prram error 下载错误信息
- (void)downloadFailureWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation
                                  error:(nullable NSError *)error;

@optional

/// 一个任务即将开始下载时调用，当需要显示网络活动指示器的时候调用
/// 此时应该在此回调中使用 UIApplication's setNetworkActivityIndicatorVisible: 去设置状态栏网络活动的可见性
- (void)downloadTaskWillBeginWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation;


/// 下载进度改变的时候调用
/// @param downloadOperation 当前下载任务
- (void)downloadProgressChangeWithDownloadOperation:(id<FileDownloadOperation>)downloadOperation;

/// 下载暂停时调用
/// @param url 当前下载任务的url
- (void)downloadPausedWithURL:(NSString *)url;

/// 回调此方法，验证下载数据
/// @param aLocalFileURL 下载文件的本地路径
/// @param url 当前下载任务的url
/// @return 如果本地文件中下载的数据通过验证测试，则应该renturn YES
/// @discussion 有时下载的数据可能是错误的， 此方法可用于检查下载的数据是否为预期的内容和数据类型，default YES
- (BOOL)downloadLocalFolderURL:(NSURL *)aLocalFileURL isVaildByURL:(NSString *)url;

/// 回调此方法，验证HTTP 状态码 是否有效
/// @param aHttpStatusCode 当前服务器响应的HTTP 状态码
/// @param url 当前下载任务的url
/// @return 如果HTTP状态码正确，则应该return YES
/// @discussion 默认范围HTTP状态码从200-299都是正确的，如果默认的范围与公司服务器不符合，可实现此方法设置
- (BOOL)httpStatusCode:(NSInteger)aHttpStatusCode isVaildByURL:(NSString *)url;


/// 回调此方法，进行SSL认证的设置
/// @param aChallenge 认证
/// @param url 当前下载任务的url
/// @param aCompletionHandler 此block用于配置调用完成回调
- (void)authenticationChallenge:(NSURLAuthenticationChallenge *)aChallenge
                            url:(NSString *)url
              completionHandler:(void (^)(NSURLCredential * aCredential, NSURLSessionAuthChallengeDisposition disposition))aCompletionHandler;


/// 一个任务进入等待时调用
- (void)downloadDidWaitingWithURLPath:(NSString *)url progress:(FileDownloadProgress *)progress;

/// 从等待队列中开始下载一个任务时调用
- (void)downloadStartFromWaitingQueueWithURLPath:(NSString *)url progress:(FileDownloadProgress *)progress;
@end


NS_ASSUME_NONNULL_END
