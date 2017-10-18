//
//  FileItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "FileDownloaderDelegate.h"
#import "FileDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileItem : FileDownloadOperation

@property (nonatomic, assign) FileDownloadStatus status;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, copy) void (^statusChangeHandler)(FileDownloadStatus status);

- (instancetype)initWithURL:(NSString *)urlPath NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithURL:(NSString *)urlPath sessionDataTask:(nullable NSURLSessionDataTask *)sessionDownloadTask NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
