//
//  OSDownloadProgress.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloadProgress.h"

static NSString * const OSProgressKey = @"progress";
static NSString * const OSExpectedFileTotalSizeKey = @"expectedFileTotalSize";
static NSString * const OSReceivedFileSizeKey = @"receivedFileSize";
static NSString * const OSeEtimatedRemainingTimeKet = @"estimatedRemainingTime";
static NSString * const OSBytesPerSecondSpeedKey = @"bytesPerSecondSpeed";
static NSString * const OSEstimatedRemainingTimeKey = @"estimatedRemainingTime";
static NSString * const OSLastLocalizedDescriptionkey = @"lastLocalizedDescription";
static NSString * const OSLastLocalizedAdditionalDescription = @"lastLocalizedAdditionalDescription";

@interface OSDownloadProgress () <NSCoding>

@property (nonatomic, assign) float progress;
@property (nonatomic, assign) int64_t expectedFileTotalSize;
@property (nonatomic, assign) int64_t receivedFileSize;
@property (nonatomic, assign) NSTimeInterval estimatedRemainingTime;
@property (nonatomic, assign) NSUInteger bytesPerSecondSpeed;
@property (nonatomic, strong) NSProgress *nativeProgress;

@end

@implementation OSDownloadProgress

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



- (NSString *)description {
    NSMutableDictionary *aDescriptionDict = [NSMutableDictionary dictionary];
    [aDescriptionDict setObject:@(self.progress) forKey:OSProgressKey];
    [aDescriptionDict setObject:@(self.expectedFileTotalSize) forKey:OSExpectedFileTotalSizeKey];
    [aDescriptionDict setObject:@(self.receivedFileSize) forKey:OSReceivedFileSizeKey];
    [aDescriptionDict setObject:@(self.estimatedRemainingTime) forKey:OSEstimatedRemainingTimeKey];
    [aDescriptionDict setObject:@(self.bytesPerSecondSpeed) forKey:OSBytesPerSecondSpeedKey];
    [aDescriptionDict setObject:self.nativeProgress forKey:@"nativeProgress"];
    if (self.lastLocalizedDescription) {
        [aDescriptionDict setObject:self.lastLocalizedDescription forKey:OSLastLocalizedDescriptionkey];
    }
    if (self.lastLocalizedAdditionalDescription)  {
        [aDescriptionDict setObject:self.lastLocalizedAdditionalDescription forKey:OSLastLocalizedAdditionalDescription];
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
    
    [coder encodeFloat:self.progress forKey:OSProgressKey];
    [coder encodeInteger:self.expectedFileTotalSize forKey:OSExpectedFileTotalSizeKey];
    [coder encodeInteger:self.receivedFileSize forKey:OSReceivedFileSizeKey];
    [coder encodeDouble:self.estimatedRemainingTime forKey:OSEstimatedRemainingTimeKey];
    [coder encodeInteger:self.bytesPerSecondSpeed forKey:OSBytesPerSecondSpeedKey];
    if (self.lastLocalizedDescription) {
        [coder encodeObject:self.lastLocalizedDescription forKey:OSLastLocalizedDescriptionkey];
    }
    if (self.lastLocalizedAdditionalDescription) {
        [coder encodeObject:self.lastLocalizedAdditionalDescription forKey:OSLastLocalizedAdditionalDescription];
    }
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.progress = [coder decodeFloatForKey:OSProgressKey];
        self.expectedFileTotalSize = [coder decodeIntegerForKey:OSExpectedFileTotalSizeKey];
        self.receivedFileSize = [coder decodeIntegerForKey:OSReceivedFileSizeKey];
        self.estimatedRemainingTime = [coder decodeDoubleForKey:OSEstimatedRemainingTimeKey];
        self.bytesPerSecondSpeed = [coder decodeIntegerForKey:OSBytesPerSecondSpeedKey];
        self.lastLocalizedDescription = [coder decodeObjectForKey:OSLastLocalizedDescriptionkey];
        self.lastLocalizedAdditionalDescription = [coder decodeObjectForKey:OSLastLocalizedAdditionalDescription];
    }
    return self;
}

@end
