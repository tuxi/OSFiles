//
//  OSDownloaderManager.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloadProtocol.h"
#import "OSDownloadProgress.h"

typedef void (^OSBackgroundSessionCompletionHandler)();
typedef void (^OSDownloaderResumeDataHandler)(NSData * aResumeData);

FOUNDATION_EXTERN NSString * const OS_Downloader_Folder;

@interface OSDownloaderManager : NSObject

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ initialize ~~~~~~~~~~~~~~~~~~~~~~~


/// 初始化OSDownloaderManager
/// @param aDelegate 下载事件的代理对象，需遵守OSDownloadProtocol协议
/// @return OSDownloaderManager初始化的对象
- (instancetype)initWithDelegate:(id<OSDownloadProtocol>)aDelegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 初始化OSDownloaderManager
/// @param aDelegate 下载事件的代理对象，需遵守OSDownloadProtocol协议
/// @param maxConcurrentDownloads 同时并发最大的下载数量，default 没有限制
/// @return OSDownloaderManager初始化的对象
- (instancetype)initWithDelegate:(id<OSDownloadProtocol>)aDelegate
          maxConcurrentDownloads:(NSInteger)maxConcurrentDownloads NS_DESIGNATED_INITIALIZER;

/// 设置任务下载完成的回调
- (void)setupTasksWithCompletionHandler:(void (^)())completionHandler;

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ download operation ~~~~~~~~~~~~~~~~~~~~~~~

/// 执行开始下载任务
/// @param urlPath 下载任务的remote url path
- (void)downloadWithURL:(NSString *)urlPath;

/// 执行开始下载任务
/// @param urlPath 下载任务的remote url path
/// @param resumeData 之前下载的数据
- (void)downloadWithURL:(NSString *)urlPath resumeData:(NSData *)resumeData;

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ download status ~~~~~~~~~~~~~~~~~~~~~~~


/// 根据是否urlPath判断正在下载中
/// @param urlPath 下载任务的url
- (BOOL)isDownloadingByURL:(NSString *)urlPath;

/// 根据是否urlPath判断在等待中
/// @param urlPath 下载任务的url
- (BOOL)isWaitingByURL:(NSString *)urlPath;

/// 当前是否有任务下载
- (BOOL)hasActiveDownloads;

/// 取消下载
/// @param urlPath 下载任务
- (void)cancelWithURL:(NSString *)urlPath;

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Background session completionHandler ~~~~~~~~~~~~~~~~~~~~~~~


/// 当完成一个后台任务时回调
- (void)setBackgroundSessionCompletionHandler:(OSBackgroundSessionCompletionHandler)completionHandler;


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Progress ~~~~~~~~~~~~~~~~~~~~~~~


/// 获取下载进度
/// urlPath 当前下载任务的唯一标识符
/// @return 下载进度的信息
- (OSDownloadProgress *)getDownloadProgressByURL:(NSString *)urlPath;
@end
