//
//  OSFileItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDownloaderDelegate.h"
#import "OSDownloadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSFileItem : OSDownloadOperation

@property (nonatomic, assign) OSFileDownloadStatus status;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, copy) void (^statusChangeHandler)(OSFileDownloadStatus status);

- (instancetype)initWithURL:(NSString *)urlPath NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithURL:(NSString *)urlPath sessionDataTask:(nullable NSURLSessionDataTask *)sessionDownloadTask NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
