//
//  OSFileItem.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileItem.h"

@interface OSFileItem ()

@property (nonatomic, strong) NSURL *finalLocalFileURL;

@end


@implementation OSFileItem

- (instancetype)init {
    NSAssert(NO, @"use - initWithURL:");
    @throw nil;
}
+ (instancetype)new {
    NSAssert(NO, @"use - initWithURL:");
    @throw nil;
}

- (instancetype)initWithURL:(NSString *)urlPath {
    
    if (self = [super initWithURL:urlPath sessionDataTask:nil]) {
        self.status = OSFileDownloadStatusNotStarted;
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.urlPath forKey:NSStringFromSelector(@selector(urlPath))];
    [aCoder encodeObject:@(self.status) forKey:NSStringFromSelector(@selector(status))];
    if (self.progressObj) {
        [aCoder encodeObject:self.progressObj forKey:NSStringFromSelector(@selector(progressObj))];
    }
    if (self.downloadError) {
        [aCoder encodeObject:self.downloadError forKey:NSStringFromSelector(@selector(downloadError))];
    }
    if (self.errorMessagesStack) {
        [aCoder encodeObject:self.errorMessagesStack forKey:NSStringFromSelector(@selector(errorMessagesStack))];
    }
    if (self.finalLocalFileURL) {
        [aCoder encodeObject:self.finalLocalFileURL forKey:NSStringFromSelector(@selector(finalLocalFileURL))];
    }
    [aCoder encodeObject:@(self.lastHttpStatusCode) forKey:NSStringFromSelector(@selector(lastHttpStatusCode))];
    if (self.fileName) {
        [aCoder encodeObject:self.fileName forKey:NSStringFromSelector(@selector(fileName))];
    }
    if (self.MIMEType) {
        [aCoder encodeObject:self.MIMEType forKey:NSStringFromSelector(@selector(MIMEType))];
    }
}


- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super init];
    if (self)
    {
        self.urlPath = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(urlPath))];
        self.status = [[aCoder decodeObjectForKey:NSStringFromSelector(@selector(status))] unsignedIntegerValue];
        self.progressObj = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(progressObj))];
        self.downloadError = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(downloadError))];
        self.errorMessagesStack = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(errorMessagesStack))];
        self.lastHttpStatusCode = [[aCoder decodeObjectForKey:NSStringFromSelector(@selector(lastHttpStatusCode))] integerValue];
        self.finalLocalFileURL = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(finalLocalFileURL))];
        self.fileName = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(fileName))];
        self.MIMEType = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(MIMEType))];
    }
    return self;
}


- (NSURL *)finalLocalFileURL {
    @synchronized (self) {
        // 处理下载完成后保存的本地路径，由于归档之前获取到的绝对路径，而沙盒路径发送改变时，根据绝对路径是找到文件的
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *documentDirectoryName = [documentPath lastPathComponent];
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *cacheDirectoryName = [cachesPath lastPathComponent];
        
        NSArray *pathComponents = [_finalLocalFileURL pathComponents];
        
        if ([pathComponents containsObject:documentDirectoryName]) {
            NSString *urlPath = _finalLocalFileURL.path;
            NSArray *subList = [urlPath componentsSeparatedByString:documentDirectoryName];
            NSString *relativePath = [subList lastObject];
            NSString *newPath = [documentPath stringByAppendingString:relativePath];
            _finalLocalFileURL = [NSURL fileURLWithPath:newPath];
        } else if ([pathComponents componentsJoinedByString:cacheDirectoryName]) {
            NSString *urlPath = _finalLocalFileURL.path;
            NSArray *subList = [urlPath componentsSeparatedByString:cacheDirectoryName];
            NSString *relativePath = [subList lastObject];
            NSString *newPath = [cachesPath stringByAppendingString:relativePath];
            _finalLocalFileURL = [NSURL fileURLWithPath:newPath];
        }
        
        return _finalLocalFileURL;
        
    }
}

- (NSString *)fileName {
    @synchronized (self) {
        if (!_fileName.length) {
            return _fileName = self.urlPath.lastPathComponent;
        };
        return _fileName;
    }
    
}

- (void)setStatus:(OSFileDownloadStatus)status {
    if (_status == status) {
        return;
    }
    [self willChangeValueForKey:@"status"];
    _status = status;
    if (self.statusChangeHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.statusChangeHandler(status);
        });
    }
    [self didChangeValueForKey:@"status"];
    
}


#pragma mark - Description


- (NSString *)description {
    NSMutableDictionary *descriptionDict = [NSMutableDictionary dictionary];
    [descriptionDict setObject:self.urlPath forKey:@"urlPath"];
    [descriptionDict setObject:@(self.status) forKey:@"status"];
    if (self.progressObj)
    {
        [descriptionDict setObject:self.progressObj forKey:@"progressObj"];
    }
    if (self.finalLocalFileURL) {
        [descriptionDict setObject:self.finalLocalFileURL forKey:@"localFileURL"];
    }
    if (self.fileName) {
        [descriptionDict setObject:self.fileName forKey:@"fileName"];
    }
    if (self.MIMEType) {
        [descriptionDict setObject:self.MIMEType forKey:@"MIMEType"];
    }
    
    NSString *description = [NSString stringWithFormat:@"%@", descriptionDict];
    
    return description;
}


@end
