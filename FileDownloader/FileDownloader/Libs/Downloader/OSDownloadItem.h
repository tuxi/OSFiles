//
//  OSDownloadItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSDownloadItem : NSObject
/*
 * 此类由OSDownloaderManager内部使用的
 */

/** 开始下载时的时间 */
@property (nonatomic, strong) NSDate *downloadStartDate;
/** 预计文件的总大小字节数 */
@property (nonatomic, assign) int64_t expectedFileTotalSize;
/** 已下载文件的大小字节数 */
@property (nonatomic, assign) int64_t receivedFileSize;
/** 恢复下载时所在文件的字节数 */
@property (nonatomic, assign) ino64_t resumedFileSizeInBytes;
/** 每秒下载的字节数 */
@property (nonatomic, assign) NSUInteger bytesPerSecondSpeed;
/** 下载进度 */
@property (nonatomic, strong, readonly) NSProgress *naviteProgress;
/** 下载的url */
@property (nonatomic, copy, readonly) NSString *urlPath;
/** 下载会话对象 NSURLSessionDownloadTask */
@property (nonatomic, strong, readonly) NSURLSessionDownloadTask *sessionDownloadTask;
/** 下载时发送的错误信息栈 */
@property (nonatomic, strong) NSArray<NSString *> *errorMessagesStack;
/** 最后的HTTP状态码 */
@property (nonatomic, assign) NSInteger lastHttpStatusCode;
/** 最终文件存储的本地路径 */
@property (nonatomic, strong) NSURL *finalLocalFileURL;

/// 初始化OSDownloadItem，
- (instancetype)initWithURL:(NSString *)urlPath sessionDownloadTask:(NSURLSessionDownloadTask *)sessionDownloadTask NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
