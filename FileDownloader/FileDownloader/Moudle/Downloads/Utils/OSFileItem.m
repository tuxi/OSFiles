//
//  OSFileItem.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileItem.h"

@interface OSFileItem ()

@property (nonatomic, strong) NSURL *localURL;

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
    if (self.localFolderURL) {
        [aCoder encodeObject:self.localFolderURL forKey:NSStringFromSelector(@selector(localFolderURL))];
    }
    [aCoder encodeObject:@(self.lastHttpStatusCode) forKey:NSStringFromSelector(@selector(lastHttpStatusCode))];
    if (self.fileName) {
        [aCoder encodeObject:self.fileName forKey:NSStringFromSelector(@selector(fileName))];
    }
    if (self.MIMEType) {
        [aCoder encodeObject:self.MIMEType forKey:NSStringFromSelector(@selector(MIMEType))];
    }
    if (self.localURL) {
        [aCoder encodeObject:self.localURL forKey:NSStringFromSelector(@selector(localURL))];
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
        self.localFolderURL = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(localFolderURL))];
        self.fileName = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(fileName))];
        self.MIMEType = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(MIMEType))];
        self.localURL = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(localURL))];
    }
    return self;
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
    if (self.localFolderURL) {
        [descriptionDict setObject:self.localFolderURL forKey:@"localFolderURL"];
    }
    if (self.localURL) {
        [descriptionDict setObject:self.localURL forKey:@"localURL"];
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
