//
//  OSDownloaderDelegate.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OSDownloadProgress;

FOUNDATION_EXTERN NSString * const OSFileDownloadProgressChangeNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadSussessNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadFailureNotification;
FOUNDATION_EXTERN NSString * const OSFileDownloadCanceldNotification;

typedef NS_ENUM(NSUInteger, OSFileDownloadStatus) {
    OSFileDownloadStatusNotStarted = 0,
    /// 下载中
    OSFileDownloadStatusDownloading,
    /// 暂停下载
    OSFileDownloadStatusPaused,
    /// 等待下载
    OSFileDownloadStatusWaiting,
    /// 取消下载
    OSFileDownloadStatusCancelled,
    /// 下载失败
    OSFileDownloadStatusFailure,
    /// 下载完成
    OSFileDownloadStatusSuccess,
};

@protocol OSDownloadFileItemProtocol <NSObject, NSCoding>

@optional

- (NSString *)urlPath;

- (NSURL *)localFileURL;
- (void)setLocalFileURL:(NSURL *)localFileURL;

- (nullable NSData *)resumeData;
- (void)setResumeData:(nullable NSData *)resumeData;

- (OSFileDownloadStatus)status;
- (void)setStatus:(OSFileDownloadStatus)status;

- (nullable OSDownloadProgress *)progressObj;
- (void)setProgressObj:(nullable OSDownloadProgress *)progressObj;

- (NSError *)downloadError;
- (void)setDownloadError:(NSError *)downloadError;

- (nullable NSArray<NSString *> *)downloadErrorMessagesStack;
- (void)setDownloadErrorMessagesStack:(nullable NSArray<NSString *> *)downloadErrorMessagesStack;

- (NSInteger)lastHttpStatusCode;
- (void)setLastHttpStatusCode:(NSInteger)lastHttpStatusCode;

- (NSString *)fileName;
- (void)setFileName:(NSString *)fileName;

- (NSString *)MIMEType;
- (void)setMIMEType:(NSString *)MIMEType;

@end

/// 对下载进行操作指定的协议
@protocol OSDownloadOperationProtocol <NSObject>

- (void)start:(NSString *)url;
- (void)cancel:(NSString *)url;
- (void)resume:(NSString *)url;
- (void)pause:(NSString *)url;

- (NSArray<id<OSDownloadFileItemProtocol>> *)getAllSuccessItems;
- (NSArray<id<OSDownloadFileItemProtocol>> *)getActiveDownloadItems;
/// 所有展示中的文件，还未开始下载时存放的，当文件取消下载时也会存放到此数组
- (NSMutableArray<id<OSDownloadFileItemProtocol>> * _Nonnull)displayItems;

@end

@protocol OSDownloadItemProtocol <NSObject>

/// 开始下载时的时间
- (NSDate *)downloadStartDate;
- (void)setDownloadStartDate:(NSDate *)downloadStartDate;

/// 预计文件的总大小字节数
- (int64_t)expectedFileTotalSize;
- (void)setExpectedFileTotalSize:(int64_t)expectedFileTotalSize;

/// 已下载文件的大小字节数
- (int64_t)receivedFileSize;
- (void)setReceivedFileSize:(int64_t)receivedFileSize;

/// 恢复下载时所在文件的字节数
- (ino64_t)resumedFileSizeInBytes;
- (void)setResumedFileSizeInBytes:(ino64_t)resumedFileSizeInBytes;

/// 每秒下载的字节数
- (NSUInteger)bytesPerSecondSpeed;
- (void)setBytesPerSecondSpeed:(NSUInteger)bytesPerSecondSpeed;

/// 下载进度
- (nullable NSProgress *)naviteProgress;

/// 下载的url
- (NSString *)urlPath;

/// 下载会话对象 NSURLSessionDownloadTask
- (NSURLSessionDownloadTask *)sessionDownloadTask;

/// 下载时发送的错误信息栈 错误信息栈(最新的错误信息初入在第一位)
- (NSArray<NSString *> *)errorMessagesStack;
- (void)setErrorMessagesStack:(NSArray<NSString *> *)errorMessagesStack;

/// 最后的HTTP状态码
- (NSInteger)lastHttpStatusCode;
- (void)setLastHttpStatusCode:(NSInteger)lastHttpStatusCode;

/// 最终文件存储的本地路径
- (NSURL *)finalLocalFileURL;
- (void)setFinalLocalFileURL:(NSURL *)finalLocalFileURL;

/// 文件的类型
- (NSString *)MIMEType;
- (void)setMIMEType:(NSString *)MIMEType;

@end

@protocol OSDownloaderDelegate <NSObject>


/// 下载成功回调
/// @param downloadItem 下载的OSDownloadItem
- (void)downloadSuccessnWithDownloadItem:(id<OSDownloadItemProtocol>)downloadItem;

/// 一个任务下载时候时调用
/// @param downloadItem 下载的OSDownloadItem
/// @param resumeData 当前错误前已经下载的数据，当继续下载时可以复用此数据继续之前进度
/// @prram error 下载错误信息
- (void)downloadFailureWithDownloadItem:(id<OSDownloadItemProtocol>)downloadItem
                             resumeData:(nullable NSData *)resumeData
                                  error:(nullable NSError *)error;

@optional

/// 一个任务即将开始下载时调用，当需要显示网络活动指示器的时候调用
/// 此时应该在此回调中使用 UIApplication's setNetworkActivityIndicatorVisible: 去设置状态栏网络活动的可见性
- (void)downloadTaskWillBegin;

/// 一个任务下载结束时调用，当需要隐藏网络活动指示器即将结束的时候调用,不管是否成功都会调用
/// 此时应该在此回调中使用 UIApplication's setNetworkActivityIndicatorVisible: 去设置状态栏网络活动的可见性
- (void)downloadTaskDidEnd;


/// 下载进度改变的时候调用
/// @param url 当前下载任务的url
/// @param progress 当前下载任务的进度对象(包含下载进度的信息、下载速度、下载剩余时间)
- (void)downloadProgressChangeWithURL:(NSString *)url progress:(OSDownloadProgress *)progress;

/// 下载暂停时调用
/// @param url 当前下载任务的url
/// @param aResumeData 当前暂停前已下载的数据，当继续下载时可以复用此数据继续之前进度
- (void)downloadPausedWithURL:(NSString *)url resumeData:(NSData *)aResumeData;

/// 恢复下载时调用
/// @param url 当前下载任务的url
- (void)resumeDownloadWithURL:(NSString *)url;

/// 当下载的文件需要存储到本地时调用，并设置本地的路径
/// @param aRemoteURL 下载文件的服务器地址
/// @return 设置本地存储的路径
/// @discussion 虽然anIdentifier用于识别下载的任务，这里回调aRemoteURL更方便区分
- (NSURL *)finalLocalFileURLWithRemoteURL:(NSURL *)aRemoteURL;

- (NSURL *)finalLocalFolderURL;

/// 回调此方法，验证下载数据
/// @param aLocalFileURL 下载文件的本地路径
/// @param url 当前下载任务的url
/// @return 如果本地文件中下载的数据通过验证测试，则应该renturn YES
/// @discussion 有时下载的数据可能是错误的， 此方法可用于检查下载的数据是否为预期的内容和数据类型，default YES
- (BOOL)downloadFinalLocalFileURL:(NSURL *)aLocalFileURL isVaildByURL:(NSString *)url;

/// 回调此方法，验证HTTP 状态码 是否有效
/// @param aHttpStatusCode 当前服务器响应的HTTP 状态码
/// @param url 当前下载任务的url
/// @return 如果HTTP状态码正确，则应该return YES
/// @discussion 默认范围HTTP状态码从200-299都是正确的，如果默认的范围与公司服务器不符合，可实现此方法设置
- (BOOL)httpStatusCode:(NSInteger)aHttpStatusCode isVaildByURL:(NSString *)url;

/// 回调此方法，进行配置后台会话任务
/// @param aBackgroundConiguration 可以修改的后台会话对象
/// @discussion 可以修改他的timeoutIntervalForRequest, timeoutIntervalForResource, HTTPAdditionalHeaders属性
- (void)customBackgroundSessionConfiguration:(NSURLSessionConfiguration *)aBackgroundConiguration;

/// 根据aRemoteURL创建一个NSURLRequest返回
/// @param aRemoteURL 需要下载的url
/// @retun 一个自定义的NSURLRequest对象
- (NSURLRequest *)URLRequestForRemoteURL:(NSURL *)aRemoteURL;

/// 回调此方法，进行SSL认证的设置
/// @param aChallenge 认证
/// @param url 当前下载任务的url
/// @param aCompletionHandler 此block用于配置调用完成回调
- (void)authenticationChallenge:(NSURLAuthenticationChallenge *)aChallenge
                            url:(NSString *)url
              completionHandler:(void (^)(NSURLCredential * aCredential, NSURLSessionAuthChallengeDisposition disposition))aCompletionHandler;

/// 提供一个下载进度的对象，以记录下载进度
/// @return 下载进度的对象
- (NSProgress *)usingNaviteProgress;

/// 有一个任务等待下载时调用
- (void)downloadDidWaitingWithURLPath:(NSString *)url progress:(OSDownloadProgress *)progress;

/// 从等待队列中开始下载一个任务
- (void)downloadStartFromWaitingQueueWithURLpath:(NSString *)url progress:(OSDownloadProgress *)progress;
@end


NS_ASSUME_NONNULL_END
