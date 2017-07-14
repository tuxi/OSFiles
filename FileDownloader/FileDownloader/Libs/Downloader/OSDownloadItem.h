//
//  OSDownloadItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "OSDownloaderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSDownloadItem : NSObject <OSDownloadItemProtocol>
/*
 * 此类由OSDownloader内部使用的
 */

/// 初始化OSDownloadItem，
- (instancetype)initWithURL:(NSString *)urlPath sessionDownloadTask:(nullable NSURLSessionTask *)sessionDownloadTask NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
