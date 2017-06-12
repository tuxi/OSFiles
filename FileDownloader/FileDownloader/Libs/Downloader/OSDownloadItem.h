//
//  OSDownloadItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "OSDownloadProtocol.h"

@interface OSDownloadItem : NSObject <OSDownloadItem>
/*
 * 此类由OSDownloaderManager内部使用的
 */



/// 初始化OSDownloadItem，
- (instancetype)initWithURL:(NSString *)urlPath sessionDownloadTask:(NSURLSessionDownloadTask *)sessionDownloadTask NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
