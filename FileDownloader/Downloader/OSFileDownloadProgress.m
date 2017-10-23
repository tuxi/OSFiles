//
//  OSFileDownloadProgress.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileDownloadProgress.h"

// 下载速度key
static NSString * const OSFileDownloadBytesPerSecondSpeedKey = @"bytesPerSecondSpeed";
// 剩余时间key
static NSString * const OSFileDownloadRemainingTimeKey = @"remainingTime";

@interface OSFileDownloadProgress () <NSCoding>

@end

@implementation OSFileDownloadProgress

@synthesize progress = _progress;

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////


- (instancetype)init {
    
    NSAssert(NO, @"use - initWithDownloadProgress:expectedFileSize:receivedFileSize:estimatedRemainingTime:bytesPerSecondSpeed:nativeProgress:");
    @throw nil;
}
+ (instancetype)new {
    NSAssert(NO, @"use - initWithDownloadProgress:expectedFileSize:receivedFileSize:estimatedRemainingTime:bytesPerSecondSpeed:nativeProgress:");
    @throw nil;
}

- (instancetype)initWithDownloadProgress:(float)aDownloadProgress
                        expectedFileSize:(int64_t)expectedFileSize
                        receivedFileSize:(int64_t)receivedFileSize
                  estimatedRemainingTime:(NSTimeInterval)estimatedRemainingTime
                     bytesPerSecondSpeed:(NSUInteger)bytesPerSecondSpeed
                          nativeProgress:(NSProgress *)nativeProgress {
    if (self = [super init]) {
        self.progress = aDownloadProgress;
        self.expectedFileTotalSize = expectedFileSize;
        self.receivedFileSize = receivedFileSize;
        self.estimatedRemainingTime = estimatedRemainingTime;
        self.bytesPerSecondSpeed = bytesPerSecondSpeed;
        self.nativeProgress = nativeProgress;
        
    }
    return self;
}

- (void)setExpectedFileTotalSize:(int64_t)expectedFileTotalSize {
    
    _expectedFileTotalSize = expectedFileTotalSize;
    if (expectedFileTotalSize > 0) {
        self.nativeProgress.totalUnitCount = expectedFileTotalSize;
    }
}

- (void)setReceivedFileSize:(int64_t)receivedFileSize {
    
    _receivedFileSize = receivedFileSize;
    if (receivedFileSize > 0) {
        if (self.expectedFileTotalSize > 0) {
            self.nativeProgress.completedUnitCount = receivedFileSize;
        }
        float progress = 0.0;
        if (self.expectedFileTotalSize > 0) {
            progress = (float)self.receivedFileSize / (float)self.expectedFileTotalSize;
        }
        
        NSDictionary *remainingTimeDict = [self remainingTimeAndBytesPerSecond];
        [self.nativeProgress setUserInfoObject:[remainingTimeDict objectForKey:OSFileDownloadRemainingTimeKey] forKey:NSProgressEstimatedTimeRemainingKey];
        [self.nativeProgress setUserInfoObject:[remainingTimeDict objectForKey:OSFileDownloadBytesPerSecondSpeedKey] forKey:NSProgressThroughputKey];
        self.estimatedRemainingTime = [remainingTimeDict[OSFileDownloadRemainingTimeKey] doubleValue];
        self.bytesPerSecondSpeed = [remainingTimeDict[OSFileDownloadBytesPerSecondSpeedKey] unsignedIntegerValue];
        self.progress = progress;
        
    }
}

- (void)setProgress:(float)progress {
    _progress = progress;
    if (self.progressHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressHandler(self.nativeProgress);
        });
    }
}

/// 计算当前下载的剩余时间和每秒下载的字节数
- (NSDictionary *)remainingTimeAndBytesPerSecond {
    // 下载剩余时间
    NSTimeInterval remainingTimeInterval = 0.0;
    // 当前下载的速度
    NSUInteger bytesPerSecondsSpeed = 0;
    if ((self.receivedFileSize > 0) && (self.expectedFileTotalSize > 0)) {
        float aSmoothingFactor = 0.8; // range 0.0 ... 1.0 (determines the weight of the current speed calculation in relation to the stored past speed value)
        NSTimeInterval downloadDurationUntilNow = [[NSDate date] timeIntervalSinceDate:self.downloadStartDate];
        int64_t aDownloadedFileSize = self.receivedFileSize - self.resumedFileSizeInBytes;
        float aCurrentBytesPerSecondSpeed = (downloadDurationUntilNow > 0.0) ? (aDownloadedFileSize / downloadDurationUntilNow) : 0.0;
        float aNewWeightedBytesPerSecondSpeed = 0.0;
        if (self.bytesPerSecondSpeed > 0.0)
        {
            aNewWeightedBytesPerSecondSpeed = (aSmoothingFactor * aCurrentBytesPerSecondSpeed) + ((1.0 - aSmoothingFactor) * (float)self.bytesPerSecondSpeed);
        } else {
            aNewWeightedBytesPerSecondSpeed = aCurrentBytesPerSecondSpeed;
        } if (aNewWeightedBytesPerSecondSpeed > 0.0) {
            remainingTimeInterval = (self.expectedFileTotalSize - self.resumedFileSizeInBytes - aDownloadedFileSize) / aNewWeightedBytesPerSecondSpeed;
        }
        bytesPerSecondsSpeed = (NSUInteger)aNewWeightedBytesPerSecondSpeed;
        self.bytesPerSecondSpeed = bytesPerSecondsSpeed;
    }
    return @{
             OSFileDownloadBytesPerSecondSpeedKey : @(bytesPerSecondsSpeed),
             OSFileDownloadRemainingTimeKey: @(remainingTimeInterval)};
}




- (NSString *)description {
    NSMutableDictionary *aDescriptionDict = [NSMutableDictionary dictionary];
    [aDescriptionDict setObject:@(self.progress) forKey:NSStringFromSelector(@selector(progress))];
    [aDescriptionDict setObject:@(self.expectedFileTotalSize) forKey:NSStringFromSelector(@selector(expectedFileTotalSize))];
    [aDescriptionDict setObject:@(self.receivedFileSize) forKey:NSStringFromSelector(@selector(receivedFileSize))];
    [aDescriptionDict setObject:@(self.estimatedRemainingTime) forKey:NSStringFromSelector(@selector(estimatedRemainingTime))];
    [aDescriptionDict setObject:@(self.bytesPerSecondSpeed) forKey:NSStringFromSelector(@selector(bytesPerSecondSpeed))];
    [aDescriptionDict setObject:self.nativeProgress forKey:@"nativeProgress"];
    if (self.lastLocalizedDescription) {
        [aDescriptionDict setObject:self.lastLocalizedDescription forKey:NSStringFromSelector(@selector(lastLocalizedDescription))];
    }
    if (self.lastLocalizedAdditionalDescription)  {
        [aDescriptionDict setObject:self.lastLocalizedAdditionalDescription forKey:NSStringFromSelector(@selector(lastLocalizedAdditionalDescription))];
    }
    
    NSString *aDescriptionString = [NSString stringWithFormat:@"%@", aDescriptionDict];
    
    return aDescriptionString;
}

- (float)progress {
    return _progress ?: self.nativeProgress.fractionCompleted;
}



////////////////////////////////////////////////////////////////////////
#pragma mark - NSCoding
////////////////////////////////////////////////////////////////////////

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeFloat:self.progress forKey:NSStringFromSelector(@selector(progress))];
    [coder encodeInteger:self.expectedFileTotalSize forKey:NSStringFromSelector(@selector(expectedFileTotalSize))];
    [coder encodeInteger:self.receivedFileSize forKey:NSStringFromSelector(@selector(receivedFileSize))];
    [coder encodeDouble:self.estimatedRemainingTime forKey:NSStringFromSelector(@selector(estimatedRemainingTime))];
    [coder encodeInteger:self.bytesPerSecondSpeed forKey:NSStringFromSelector(@selector(bytesPerSecondSpeed))];
    if (self.lastLocalizedDescription) {
        [coder encodeObject:self.lastLocalizedDescription forKey:NSStringFromSelector(@selector(lastLocalizedDescription))];
    }
    if (self.lastLocalizedAdditionalDescription) {
        [coder encodeObject:self.lastLocalizedAdditionalDescription forKey:NSStringFromSelector(@selector(lastLocalizedAdditionalDescription))];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.progress = [coder decodeFloatForKey:NSStringFromSelector(@selector(progress))];
        self.expectedFileTotalSize = [coder decodeIntegerForKey:NSStringFromSelector(@selector(expectedFileTotalSize))];
        self.receivedFileSize = [coder decodeIntegerForKey:NSStringFromSelector(@selector(receivedFileSize))];
        self.estimatedRemainingTime = [coder decodeDoubleForKey:NSStringFromSelector(@selector(estimatedRemainingTime))];
        self.bytesPerSecondSpeed = [coder decodeIntegerForKey:NSStringFromSelector(@selector(bytesPerSecondSpeed))];
        self.lastLocalizedDescription = [coder decodeObjectForKey:NSStringFromSelector(@selector(lastLocalizedDescription))];
        self.lastLocalizedAdditionalDescription = [coder decodeObjectForKey:NSStringFromSelector(@selector(lastLocalizedAdditionalDescription))];
    }
    return self;
}

@end
