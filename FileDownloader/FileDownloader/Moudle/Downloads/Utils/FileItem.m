//
//  FileItem.m
//  FileDownloader
//
//  Created by Swae on 2017/10/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FileItem.h"

@implementation FileItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = FileDownloadStatusNotStarted;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        self.packageId = [coder decodeObjectForKey:NSStringFromSelector(@selector(packageId))];
        self.urlPath = [coder decodeObjectForKey:NSStringFromSelector(@selector(urlPath))];
        self.status = [coder decodeIntegerForKey:NSStringFromSelector(@selector(status))];
        self.MIMEType = [coder decodeObjectForKey:NSStringFromSelector(@selector(MIMEType))];
        self.fileName = [coder decodeObjectForKey:NSStringFromSelector(@selector(fileName))];
        self.lastHttpStatusCode = [coder decodeIntegerForKey:NSStringFromSelector(@selector(lastHttpStatusCode))];
        self.downloadError = [coder decodeObjectForKey:NSStringFromSelector(@selector(downloadError))];
        self.errorMessagesStack = [coder decodeObjectForKey:NSStringFromSelector(@selector(errorMessagesStack))];
        self.progressObj = [coder decodeObjectForKey:NSStringFromSelector(@selector(progressObj))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.packageId forKey:NSStringFromSelector(@selector(packageId))];
    [aCoder encodeObject:self.urlPath forKey:NSStringFromSelector(@selector(urlPath))];
    [aCoder encodeInteger:self.status forKey:NSStringFromSelector(@selector(status))];
    [aCoder encodeObject:self.MIMEType forKey:NSStringFromSelector(@selector(MIMEType))];
    [aCoder encodeObject:self.fileName forKey:NSStringFromSelector(@selector(fileName))];
    [aCoder encodeInteger:self.lastHttpStatusCode forKey:NSStringFromSelector(@selector(lastHttpStatusCode))];
    [aCoder encodeObject:self.downloadError forKey:NSStringFromSelector(@selector(downloadError))];
    [aCoder encodeObject:self.errorMessagesStack forKey:NSStringFromSelector(@selector(errorMessagesStack))];
    [aCoder encodeObject:self.progressObj forKey:NSStringFromSelector(@selector(progressObj))];
}

- (NSString *)localFolderPath {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (NSString *)localPath {
    return [self.localFolderPath stringByAppendingPathComponent:self.fileName];
}

@end
