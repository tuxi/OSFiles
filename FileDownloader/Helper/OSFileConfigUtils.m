//
//  OSFileConfigUtils.m
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileConfigUtils.h"

static NSString * const OSFileConfigMaxConcurrentDownloadsKey = @"OSFileConfigMaxConcurrentDownloadsKey";
static NSString * const OSFileConfigAutoDownloadWhenFailureKey = @"OSFileConfigAutoDownloadWhenFailureKey";
static NSString * const OSFileConfigAutoDownloadWhenInitializeKey = @"OSFileConfigAutoDownloadWhenInitializeKey";

@implementation OSFileConfigUtils

+ (OSFileConfigUtils *)manager {
    static OSFileConfigUtils *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [OSFileConfigUtils new];
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

- (void)setShouldAutoDownloadWhenInitialize:(NSNumber *)shouldAutoDownloadWhenInitialize {
    [[NSUserDefaults standardUserDefaults] setObject:shouldAutoDownloadWhenInitialize forKey:OSFileConfigAutoDownloadWhenInitializeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)shouldAutoDownloadWhenInitialize {
    return [[NSUserDefaults standardUserDefaults] objectForKey:OSFileConfigAutoDownloadWhenInitializeKey];
}

+ (NSString *)getDownloadLocalFolderPath {
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *localFolderPath = [documents stringByAppendingPathComponent:@"OSFileDownloader"];
    BOOL isDirectory, isExist;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:localFolderPath isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:localFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return localFolderPath;
}

+ (NSString *)getDocumentPath {
    
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
}

+ (NSString *)getLibraryPath {
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}

+ (NSString *)getCachesPath {
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [userPaths objectAtIndex:0];
}

@end
