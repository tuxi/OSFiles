//
//  OSFileConfigManager.h
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSFileConfigManager : NSObject

/// 最大同时下载数量，default is 3
@property (nonatomic, strong) NSNumber *maxConcurrentDownloads;
/// 下载失败是否自动重试
@property (nonatomic, strong) NSNumber *shouldAutoDownloadWhenFailure;

+ (OSFileConfigManager *)manager;

@end
