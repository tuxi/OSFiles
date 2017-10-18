//
//  FileDownloadOperation.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FileDownloadOperation.h"


@interface FileDownloadOperation ()

/** 恢复下载时所在文件的字节数 */
@property (nonatomic, assign) ino64_t resumedFileSizeInBytes;
/** 下载的url */
@property (nonatomic, copy) NSString *urlPath;
/** 下载会话对象 NSURLSessionDownloadTask */
@property (nonatomic, strong) NSURLSessionTask *sessionTask;
/** 下载时发送的错误信息栈 */
@property (nonatomic, strong) NSArray<NSString *> *errorMessagesStack;
/** 最后的HTTP状态码 */
@property (nonatomic, assign) NSInteger lastHttpStatusCode;
/** 最终文件存储的本地目录 */
@property (nonatomic, strong) NSURL *localFolderURL;
/** 最终文件存储的本地完整路径，默认是所在的目录+文件名(下载url名称) */
@property (nonatomic, strong) NSURL *localURL;
/** 文件的类型 */
@property (nonatomic, copy) NSString *MIMEType;
/** 文件名称，默认就是下载的url的后缀 */
@property (nonatomic, copy) NSString *fileName;
/** 流 */
@property (nonatomic, strong) NSOutputStream *outputStream;

@property (nonatomic, strong) FileDownloadProgress *progressObj;

@end

@implementation FileDownloadOperation

////////////////////////////////////////////////////////////////////////
#pragma mark - initialize
////////////////////////////////////////////////////////////////////////

@synthesize
cancellationHandler = _cancellationHandler,
pausingHandler = _pausingHandler,
resumingHandler = _resumingHandler;

- (instancetype)initWithURL:(NSString *)urlPath
            sessionDataTask:(NSURLSessionDataTask *)sessionDownloadTask {
    if (self = [super init]) {
        self.urlPath = urlPath;
        self.sessionTask = sessionDownloadTask;
        self.resumedFileSizeInBytes = 0;
        self.lastHttpStatusCode = 0;
        
        NSProgress *progress = [[NSProgress alloc] initWithParent:[NSProgress currentProgress] userInfo:nil];
        progress.kind = NSProgressKindFile;
        [progress setUserInfoObject:NSProgressFileOperationKindKey forKey:NSProgressFileOperationKindDownloading];
        [progress setUserInfoObject:urlPath forKey:@"urlPath"];
        progress.cancellable = YES;
        progress.pausable = YES;
        progress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        progress.completedUnitCount = 0;
        
        self.progressObj = [[FileDownloadProgress alloc] initWithDownloadProgress:0
                                                               expectedFileSize:0
                                                               receivedFileSize:0
                                                         estimatedRemainingTime:0
                                                            bytesPerSecondSpeed:0
                                                                 nativeProgress:progress];
        
    }
    return self;
}

- (void)pause {
    if (self.progressObj.nativeProgress) {
        [self.progressObj.nativeProgress pause];
    }
    else if (self.pausingHandler) {
        self.pausingHandler();
    }
}

- (void)cancel {
    if (self.progressObj.nativeProgress) {
        [self.progressObj.nativeProgress cancel];
    }
    else if (self.cancellationHandler) {
        self.cancellationHandler();
    }
}

- (void)resume {
    if ([self.progressObj.nativeProgress respondsToSelector:@selector(resume)]) {
        [self.progressObj.nativeProgress resume];
    }
    else if (self.resumingHandler) {
            self.resumingHandler();
    }
}




- (void)dealloc {
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

- (void)setCancellationHandler:(void (^)(void))cancellationHandler {
    _cancellationHandler = cancellationHandler;
    [self.progressObj.nativeProgress setCancellationHandler:cancellationHandler];
}

- (void (^)(void))cancellationHandler {
    return self.progressObj.nativeProgress.cancellationHandler;
}

- (void)setPausingHandler:(void (^)(void))pausingHandler {
    _pausingHandler = pausingHandler;
    [self.progressObj.nativeProgress setPausingHandler:pausingHandler];
}

- (void (^)(void))pausingHandler {
    return self.progressObj.nativeProgress.pausingHandler;
}

- (void)setResumingHandler:(void (^)(void))resumingHandler {
    _resumingHandler = resumingHandler;
    if ([self.progressObj.nativeProgress respondsToSelector:@selector(setResumingHandler:)]) {
        [self.progressObj.nativeProgress setResumingHandler:resumingHandler];
    }
}

- (void (^)(void))resumingHandler {
    return self.progressObj.nativeProgress.resumingHandler;
}

- (void)setProgressHandler:(void (^)(NSProgress * _Nonnull))progressHandler {
    _progressHandler = progressHandler;
    self.progressObj.progressHandler = progressHandler;
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////

//- (NSURL *)localFolderURL {
//    @synchronized (self) {
//        // 处理下载完成后保存的本地路径，由于归档之前获取到的绝对路径，而沙盒路径发送改变时，根据绝对路径是找到文件的
//        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//        NSString *documentDirectoryName = [documentPath lastPathComponent];
//        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
//        NSString *cacheDirectoryName = [cachesPath lastPathComponent];
//
//        NSArray *pathComponents = [_localFolderURL pathComponents];
//
//        if ([pathComponents containsObject:documentDirectoryName]) {
//            NSString *urlPath = _localFolderURL.path;
//            NSArray *subList = [urlPath componentsSeparatedByString:documentDirectoryName];
//            NSString *relativePath = [subList lastObject];
//            NSString *newPath = [documentPath stringByAppendingString:relativePath];
//            _localFolderURL = [NSURL fileURLWithPath:newPath];
//        } else if ([pathComponents componentsJoinedByString:cacheDirectoryName]) {
//            NSString *urlPath = _localFolderURL.path;
//            NSArray *subList = [urlPath componentsSeparatedByString:cacheDirectoryName];
//            NSString *relativePath = [subList lastObject];
//            NSString *newPath = [cachesPath stringByAppendingString:relativePath];
//            _localFolderURL = [NSURL fileURLWithPath:newPath];
//        }
//
//        return _localFolderURL;
//        
//    }
//}

- (NSURL *)localURL {
    NSString *fullLocalPath = [self.localFolderURL.path stringByAppendingPathComponent:self.fileName];
    if (!fullLocalPath) {
        return nil;
    }
    return [NSURL fileURLWithPath:fullLocalPath];
}

- (NSString *)fileName {
    @synchronized (self) {
        if (!_fileName.length) {
            return _fileName = self.urlPath.lastPathComponent;
        };
        return _fileName;
    }
    
}


////////////////////////////////////////////////////////////////////////
#pragma mark - description
////////////////////////////////////////////////////////////////////////



- (NSString *)description {
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.urlPath forKey:@"urlPath"];
    [dict setObject:self.progressObj.description forKey:@"progressObj"];
    if (self.sessionTask) {
        [dict setObject:[NSString stringWithFormat:@"sessionTask identifier:%ld", self.sessionTask.taskIdentifier] forKey:@"taskIdentifier"];
    }
    if (self.MIMEType) {
        [dict setObject:self.MIMEType forKey:@"MIMEType"];
    }
    NSString *description = [NSString stringWithFormat:@"%@", dict];
    
    return description;
}

@end
