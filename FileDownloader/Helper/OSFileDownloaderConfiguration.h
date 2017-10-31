//
//  OSFileDownloaderConfiguration.h
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSFileDownloaderConfiguration : NSObject

/// 最大同时下载数量，default is 3
@property (nonatomic, strong) NSNumber *maxConcurrentDownloads;
/// 下载失败是否自动重试
@property (nonatomic, strong) NSNumber *shouldAutoDownloadWhenFailure;
/// app启动时是否接着上次任务继续下载
@property (nonatomic, strong) NSNumber *shouldAutoDownloadWhenInitialize;
/// 允许蜂窝网络下载，默认不允许
@property (nonatomic, strong) NSNumber *shouldAllowDownloadOnCellularNetwork;
/// 下载完成时发送通知, 默认关闭
@property (nonatomic, strong) NSNumber *shouldSendNotificationWhenDownloadComplete;

+ (OSFileDownloaderConfiguration *)defaultConfiguration;

+ (NSString *)getDownloadLocalFolderPath;

+ (NSString *)getDocumentPath;
+ (NSString *)getLibraryPath;
+ (NSString *)getCachesPath;

@end
