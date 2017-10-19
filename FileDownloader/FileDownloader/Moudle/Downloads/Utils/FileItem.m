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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.packageId forKey:NSStringFromSelector(@selector(packageId))];
    [aCoder encodeObject:self.urlPath forKey:NSStringFromSelector(@selector(urlPath))];
    [aCoder encodeInteger:self.status forKey:NSStringFromSelector(@selector(status))];
    [aCoder encodeObject:self.MIMEType forKey:NSStringFromSelector(@selector(MIMEType))];
}

@end
