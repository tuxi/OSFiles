//
//  OSFileConfigManager.m
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileConfigManager.h"

static NSString * const OSFileConfigMaxConcurrentDownloadsKey = @"OSFileConfigMaxConcurrentDownloadsKey";
static NSString * const OSFileConfigAutoDownloadWhenFailureKey = @"OSFileConfigAutoDownloadWhenFailureKey";

@implementation OSFileConfigManager

+ (OSFileConfigManager *)manager {
    static OSFileConfigManager *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [OSFileConfigManager new];
    });
    return _sharedInstance;
}


- (void)setMaxConcurrentDownloads:(NSNumber *)maxConcurrentDownloads {
    if (maxConcurrentDownloads && [maxConcurrentDownloads integerValue] <= 0) {
        maxConcurrentDownloads = @(1);
    }
    [[NSUserDefaults standardUserDefaults] setObject:maxConcurrentDownloads forKey:OSFileConfigMaxConcurrentDownloadsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)maxConcurrentDownloads {
    NSNumber * maxConcurrentDownloads = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileConfigMaxConcurrentDownloadsKey];
    if (!maxConcurrentDownloads) {
        maxConcurrentDownloads = @(3);
    }
    return maxConcurrentDownloads;
}

- (NSNumber *)shouldAutoDownloadWhenFailure {
    NSNumber * shouldAutoDownloadWhenFailure = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileConfigAutoDownloadWhenFailureKey];
    if (!shouldAutoDownloadWhenFailure) {
        shouldAutoDownloadWhenFailure = @(NO);
    }
    return shouldAutoDownloadWhenFailure;
}

- (void)setShouldAutoDownloadWhenFailure:(NSNumber *)shouldAutoDownloadWhenFailure {
    [[NSUserDefaults standardUserDefaults] setObject:shouldAutoDownloadWhenFailure forKey:OSFileConfigAutoDownloadWhenFailureKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
