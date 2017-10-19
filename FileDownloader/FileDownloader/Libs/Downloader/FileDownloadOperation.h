//
//  FileDownloadOperation.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadProgress.h"
#import "FileDownloadProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileDownloadOperation : NSObject <FileDownloadOperation>
@property (nonatomic, copy) void (^statusChangeHandler)(FileDownloadStatus status);
@property (nullable, copy) void (^cancellationHandler)(void);
@property (nullable, copy) void (^pausingHandler)(void);
@property (nullable, copy) void (^resumingHandler)(void);
@property (nonatomic, nullable, copy) void (^progressHandler)(NSProgress *progress);
@property (nonatomic, copy) void (^completionHandler)(NSURLResponse *response, NSURL * _Nullable filePath, NSError * _Nullable error);


- (void)pause;
- (void)resume;
- (void)cancel;

- (instancetype)initWithURL:(NSString *)urlPath sessionDataTask:(nullable NSURLSessionDataTask *)sessionDownloadTask;

@end

NS_ASSUME_NONNULL_END
