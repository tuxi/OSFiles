//
//  OSDownloadItem.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloadItem.h"

@interface OSDownloadItem ()

@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, strong) NSURLSessionDownloadTask *sessionDownloadTask;
@property (nonatomic, strong) NSProgress *naviteProgress;

@end

@implementation OSDownloadItem

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ initialize ~~~~~~~~~~~~~~~~~~~~~~~


- (instancetype)init {
    NSAssert(NO, @"use - initWithURL:sessionDownloadTask:");
    @throw nil;
}
+ (instancetype)new {
    NSAssert(NO, @"use - initWithURL:sessionDownloadTask:");
    @throw nil;
}

- (instancetype)initWithURL:(NSString *)urlPath sessionDownloadTask:(NSURLSessionDownloadTask *)sessionDownloadTask {
    if (self = [super init]) {
        self.urlPath = urlPath;
        self.sessionDownloadTask = sessionDownloadTask;
        self.receivedFileSize = 0;
        self.expectedFileTotalSize = 0;
        self.bytesPerSecondSpeed = 0;
        self.resumedFileSizeInBytes = 0;
        self.lastHttpStatusCode = 0;
        
        self.naviteProgress = [[NSProgress alloc] initWithParent:[NSProgress currentProgress] userInfo:nil];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            self.naviteProgress.kind = NSProgressKindFile;
            [self.naviteProgress setUserInfoObject:NSProgressFileOperationKindKey forKey:NSProgressFileOperationKindDownloading];
            [self.naviteProgress setUserInfoObject:urlPath forKey:@"urlPath"];
            self.naviteProgress.cancellable = YES;
            self.naviteProgress.pausable = YES;
            self.naviteProgress.totalUnitCount = NSURLSessionTransferSizeUnknown;
            self.naviteProgress.completedUnitCount = 0;
        }
    }
    return self;
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ set ~~~~~~~~~~~~~~~~~~~~~~~


- (void)setExpectedFileTotalSize:(int64_t)expectedFileTotalSize {
    
    _expectedFileTotalSize = expectedFileTotalSize;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        if (expectedFileTotalSize > 0) {
            self.naviteProgress.totalUnitCount = expectedFileTotalSize;
        }
    }
}

- (void)setReceivedFileSize:(int64_t)receivedFileSize {
    
    _receivedFileSize = receivedFileSize;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        if (receivedFileSize > 0) {
            if (self.expectedFileTotalSize > 0) {
                self.naviteProgress.completedUnitCount = receivedFileSize;
            }
        }
    }
}


#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ description ~~~~~~~~~~~~~~~~~~~~~~~



- (NSString *)description {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(self.receivedFileSize) forKey:@"receivedFileSize"];
    [dict setObject:@(self.expectedFileTotalSize) forKey:@"expectedFileTotalSize"];
    [dict setObject:@(self.bytesPerSecondSpeed) forKey:@"bytesPerSecondSpeed"];
    [dict setObject:self.urlPath forKey:@"urlPath"];
    [dict setObject:self.naviteProgress forKey:@"naviteProgress"];
    if (self.sessionDownloadTask) {
        [dict setObject:@(YES) forKey:@"hasSessionDownloadTask"];
    }
    NSString *description = [NSString stringWithFormat:@"%@", dict];
    
    return description;
}

@end
