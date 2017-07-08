
//
//  OSFileItem.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileItem.h"

@interface OSFileItem ()

@property (nonatomic, strong) NSString *urlPath;
@property (nonatomic, strong) NSURL *localFileURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, assign) OSFileDownloadStatus status;
@property (nonatomic, strong) OSDownloadProgress *progressObj;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, strong) NSArray<NSString *> *downloadErrorMessagesStack;
@property (nonatomic, assign) NSInteger lastHttpStatusCode;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *MIMEType;
@property (nonatomic, copy) NSString *resumeString;
@property (nonatomic, copy) NSString *tmpFilename;
@property (nonatomic, copy) NSString *resumeDirectoryStr;

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
    
    if (self = [super init]) {
        _urlPath = urlPath;
        self.status = OSFileDownloadStatusNotStarted;
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.urlPath forKey:NSStringFromSelector(@selector(urlPath))];
    [aCoder encodeObject:@(self.status) forKey:NSStringFromSelector(@selector(status))];
    if (self.resumeData.length > 0) {
        [aCoder encodeObject:self.resumeData forKey:NSStringFromSelector(@selector(resumeData))];
    } if (self.progressObj) {
        [aCoder encodeObject:self.progressObj forKey:NSStringFromSelector(@selector(progressObj))];
    } if (self.downloadError) {
        [aCoder encodeObject:self.downloadError forKey:NSStringFromSelector(@selector(downloadError))];
    } if (self.downloadErrorMessagesStack){
        [aCoder encodeObject:self.downloadErrorMessagesStack forKey:NSStringFromSelector(@selector(downloadErrorMessagesStack))];
    }
    if (self.localFileURL) {
        [aCoder encodeObject:self.localFileURL forKey:NSStringFromSelector(@selector(localFileURL))];
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
        _urlPath = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(urlPath))];
        self.status = [[aCoder decodeObjectForKey:NSStringFromSelector(@selector(status))] unsignedIntegerValue];
        self.resumeData = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(resumeData))];
        self.progressObj = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(progressObj))];
        self.downloadError = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(downloadError))];
        self.downloadErrorMessagesStack = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(downloadErrorMessagesStack))];
        self.lastHttpStatusCode = [[aCoder decodeObjectForKey:NSStringFromSelector(@selector(lastHttpStatusCode))] integerValue];
        self.localFileURL = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(localFileURL))];
        self.fileName = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(fileName))];
        self.MIMEType = [aCoder decodeObjectForKey:NSStringFromSelector(@selector(MIMEType))];
    }
    return self;
}


- (NSURL *)localFileURL {
    // 处理下载完成后保存的本地路径，由于归档之前获取到的绝对路径，而沙盒路径发送改变时，根据绝对路径是找到文件的
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *documentDirectoryName = [documentPath lastPathComponent];
    NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cacheDirectoryName = [cachesPath lastPathComponent];
    
    NSArray *pathComponents = [_localFileURL pathComponents];
    
    if ([pathComponents containsObject:documentDirectoryName]) {
        NSString *urlPath = _localFileURL.path;
        NSArray *subList = [urlPath componentsSeparatedByString:documentDirectoryName];
        NSString *relativePath = [subList lastObject];
        NSString *newPath = [documentPath stringByAppendingString:relativePath];
        _localFileURL = [NSURL fileURLWithPath:newPath];
    } else if ([pathComponents componentsJoinedByString:cacheDirectoryName]) {
        NSString *urlPath = _localFileURL.path;
        NSArray *subList = [urlPath componentsSeparatedByString:cacheDirectoryName];
        NSString *relativePath = [subList lastObject];
        NSString *newPath = [cachesPath stringByAppendingString:relativePath];
        _localFileURL = [NSURL fileURLWithPath:newPath];
    }
    return _localFileURL;
}

- (NSString *)fileName {
    if (!_fileName.length) {
        return self.urlPath.lastPathComponent;
    };
    return _fileName;
}

- (void)setStatus:(OSFileDownloadStatus)status {
    if (_status == status) {
        return;
    }
    [self willChangeValueForKey:@"status"];
    _status = status;
    [self didChangeValueForKey:@"status"];
    
}

- (void)setProgressObj:(OSDownloadProgress *)progressObj {
    _progressObj = progressObj;
    if (!progressObj) {
        NSLog(@"----");
    }
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
    if (self.resumeData.length > 0)
    {
        [descriptionDict setObject:@"resumeData exit" forKey:@"resumeData"];
    }
    if (self.localFileURL) {
        [descriptionDict setObject:self.localFileURL forKey:@"localFileURL"];
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

#pragma mark - 分析继续下载数据
- (void)parseResumeData:(NSData *)resumeData {
    if (!resumeData.length) {
        return;
    }
    NSString *XMLStr = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
    self.resumeString = [NSMutableString stringWithFormat:@"%@", XMLStr];
    
    //判断系统，iOS8以前和以后
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        //iOS8包含iOS8以前
        NSRange tmpRange = [XMLStr rangeOfString:@"NSURLSessionResumeInfoLocalPath"];
        NSString *tmpStr = [XMLStr substringFromIndex:tmpRange.location + tmpRange.length];
        NSRange oneStringRange = [tmpStr rangeOfString:@"CFNetworkDownload_"];
        NSRange twoStringRange = [tmpStr rangeOfString:@".tmp"];
        self.tmpFilename = [tmpStr substringWithRange:NSMakeRange(oneStringRange.location, twoStringRange.location + twoStringRange.length - oneStringRange.location)];
        
    } else {
        //iOS8以后
        NSRange tmpRange = [XMLStr rangeOfString:@"NSURLSessionResumeInfoTempFileName"];
        NSString *tmpStr = [XMLStr substringFromIndex:tmpRange.location + tmpRange.length];
        NSRange oneStringRange = [tmpStr rangeOfString:@"<string>"];
        NSRange twoStringRange = [tmpStr rangeOfString:@"</string>"];
        //记录tmp文件名
        self.tmpFilename = [tmpStr substringWithRange:NSMakeRange(oneStringRange.location + oneStringRange.length, twoStringRange.location - oneStringRange.location - oneStringRange.length)];
    }
    
    //有数据，保存到本地
    //存储数据
    BOOL isS = [resumeData writeToFile:self.resumeDirectoryStr atomically:NO];
    if (isS) {
        //继续存储数据成功
        NSLog(@"继续存储数据成功");
    } else {
        //继续存储数据失败
        NSLog(@"继续存储数据失败");
    }
    
}

@end
