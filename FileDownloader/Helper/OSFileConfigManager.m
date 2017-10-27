//
//  OSFileConfigManager.m
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileConfigManager.h"

static NSString * const OSFileConfigMaxConcurrentDownloadsKey = @"OSFileConfigMaxConcurrentDownloadsKey";

@implementation OSFileConfigManager

+ (OSFileConfigManager *)manager {
    static OSFileConfigManager *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [OSFileConfigManager new];
    });
    return _sharedInstance;
}


- (void)setMaxConcurrentDownloads:(NSUInteger)maxConcurrentDownloads {
    [[NSUserDefaults standardUserDefaults] setInteger:maxConcurrentDownloads forKey:OSFileConfigMaxConcurrentDownloadsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSUInteger)maxConcurrentDownloads {
    return [[NSUserDefaults standardUserDefaults] boolForKey:OSFileConfigMaxConcurrentDownloadsKey];
}

@end
