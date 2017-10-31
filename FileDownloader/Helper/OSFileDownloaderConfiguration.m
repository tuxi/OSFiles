//
//  OSFileDownloaderConfiguration.m
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileDownloaderConfiguration.h"

static NSString * const OSFileDownloaderConfigurationMaxConcurrentDownloadsKey = @"OSFileDownloaderConfigurationMaxConcurrentDownloadsKey";
static NSString * const OSFileDownloaderConfigurationAutoDownloadWhenFailureKey = @"OSFileDownloaderConfigurationAutoDownloadWhenFailureKey";
static NSString * const OSFileDownloaderConfigurationAutoDownloadWhenInitializeKey = @"OSFileDownloaderConfigurationAutoDownloadWhenInitializeKey";
static NSString * const OSFileDownloaderConfigurationAllowDownloadOnCellularNetworkKey = @"OSFileDownloaderConfigurationAllowDownloadOnCellularNetworkKey";
static NSString * const OSFileDownloaderConfigurationSendNotificationWhenDownloadCompleteKey = @"OSFileDownloaderConfigurationSendNotificationWhenDownloadCompleteKey";

@implementation OSFileDownloaderConfiguration

+ (OSFileDownloaderConfiguration *)defaultConfiguration {
    static OSFileDownloaderConfiguration *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [OSFileDownloaderConfiguration new];
    });
    return _sharedInstance;
}


- (void)setMaxConcurrentDownloads:(NSNumber *)maxConcurrentDownloads {
    if (maxConcurrentDownloads && [maxConcurrentDownloads integerValue] <= 0) {
        maxConcurrentDownloads = @(1);
    }
    [[NSUserDefaults standardUserDefaults] setObject:maxConcurrentDownloads forKey:OSFileDownloaderConfigurationMaxConcurrentDownloadsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)maxConcurrentDownloads {
    NSNumber * maxConcurrentDownloads = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileDownloaderConfigurationMaxConcurrentDownloadsKey];
    if (!maxConcurrentDownloads) {
        maxConcurrentDownloads = @(3);
    }
    return maxConcurrentDownloads;
}

- (NSNumber *)shouldAutoDownloadWhenFailure {
    NSNumber * shouldAutoDownloadWhenFailure = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileDownloaderConfigurationAutoDownloadWhenFailureKey];
    if (!shouldAutoDownloadWhenFailure) {
        shouldAutoDownloadWhenFailure = @(NO);
    }
    return shouldAutoDownloadWhenFailure;
}

- (void)setShouldAutoDownloadWhenFailure:(NSNumber *)shouldAutoDownloadWhenFailure {
    [[NSUserDefaults standardUserDefaults] setObject:shouldAutoDownloadWhenFailure forKey:OSFileDownloaderConfigurationAutoDownloadWhenFailureKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setShouldAutoDownloadWhenInitialize:(NSNumber *)shouldAutoDownloadWhenInitialize {
    [[NSUserDefaults standardUserDefaults] setObject:shouldAutoDownloadWhenInitialize forKey:OSFileDownloaderConfigurationAutoDownloadWhenInitializeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)shouldAutoDownloadWhenInitialize {
    return [[NSUserDefaults standardUserDefaults] objectForKey:OSFileDownloaderConfigurationAutoDownloadWhenInitializeKey];
}

- (void)setShouldAllowDownloadOnCellularNetwork:(NSNumber *)shouldAllowDownloadOnCellularNetwork {
    [[NSUserDefaults standardUserDefaults] setObject:shouldAllowDownloadOnCellularNetwork forKey:OSFileDownloaderConfigurationAllowDownloadOnCellularNetworkKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)shouldAllowDownloadOnCellularNetwork {
    return [[NSUserDefaults standardUserDefaults] objectForKey:OSFileDownloaderConfigurationAllowDownloadOnCellularNetworkKey];
}

- (void)setShouldSendNotificationWhenDownloadComplete:(NSNumber *)shouldSendNotificationWhenDownloadComplete {
    [[NSUserDefaults standardUserDefaults] setObject:shouldSendNotificationWhenDownloadComplete forKey:OSFileDownloaderConfigurationSendNotificationWhenDownloadCompleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)shouldSendNotificationWhenDownloadComplete {
    return [[NSUserDefaults standardUserDefaults] objectForKey:OSFileDownloaderConfigurationSendNotificationWhenDownloadCompleteKey];
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
