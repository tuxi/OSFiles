//
//  OSDownloadProgress.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSDownloadProgress : NSObject

/** 已下载的进度，0.0 ~ 1.0 */
@property (nonatomic, assign, readonly) float progress;
/** 预计文件的总大小字节数 */
@property (nonatomic, assign, readonly) int64_t expectedFileTotalSize;
/** 已下载文件的大小字节数 */
@property (nonatomic, assign, readonly) int64_t receivedFileSize;
/** 预估剩余时间 */
@property (nonatomic, assign, readonly) NSTimeInterval estimatedRemainingTime;
/** 每秒下载的字节数 */
@property (nonatomic, assign, readonly) NSUInteger bytesPerSecondSpeed;
/** 下载的进度 */
@property (nonatomic, strong, readonly) NSProgress *nativeProgress;
/** 用于存储最后的下载描述(在本地进程完成之前，存储最后的本地化描述比如暂停、取消时) */
@property (nonatomic, copy) NSString *lastLocalizedDescription;
/** 用于存储本地本地化进程的最后本地化附加说明 */
@property (nonatomic, copy) NSString *lastLocalizedAdditionalDescription;

/// 初始化方法(指定初始化方法)
/// @param aDownloadProgress 文件下载的进度 0.0 ~ 1.0
/// @param expectedFileSize 预计文件总大小字节数
/// @param receivedFileSize 已下载文件大小的字节数
/// @param estimatedRemainingTime 估计剩余下载时间(秒)
/// @param bytesPerSecondSpeed 每秒下载的字节数
/// @param nativeProgress 下载进度对象(NSProgress)
/// @return OSDownloadProgress 对象
- (instancetype)initWithDownloadProgress:(float)aDownloadProgress
                        expectedFileSize:(int64_t)expectedFileSize
                        receivedFileSize:(int64_t)receivedFileSize
                  estimatedRemainingTime:(NSTimeInterval)estimatedRemainingTime
                     bytesPerSecondSpeed:(NSUInteger)bytesPerSecondSpeed
                          nativeProgress:(NSProgress *)nativeProgress NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

@end
