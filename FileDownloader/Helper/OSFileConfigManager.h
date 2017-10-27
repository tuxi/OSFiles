//
//  OSFileConfigManager.h
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSFileConfigManager : NSObject

@property (nonatomic, assign) NSUInteger maxConcurrentDownloads;

+ (OSFileConfigManager *)manager;

@end
