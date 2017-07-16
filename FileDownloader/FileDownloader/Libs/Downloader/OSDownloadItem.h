//
//  OSDownloadItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "OSDownloaderDelegate.h"
#import "OSDownloadProgress.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSDownloadItem : NSObject <OSDownloadItemProtocol>
//
//@property (getter=isCancellable) BOOL cancellable;
//@property (getter=isPausable) BOOL pausable;
//
//@property (readonly, getter=isCancelled) BOOL cancelled;
//@property (readonly, getter=isPaused) BOOL paused;
@property (nullable, copy) void (^cancellationHandler)(void);
@property (nullable, copy) void (^pausingHandler)(void);
@property (nullable, copy) void (^resumingHandler)(void);
@property (nonatomic, nullable, copy) void (^progressHandler)(OSDownloadProgress *progressObj);
//@property (nonatomic, copy) void (^completionHandler)(BOOL isSuccess, NSError *error);


- (void)pause;
- (void)resume;
- (void)cancel;

- (instancetype)initWithURL:(NSString *)urlPath sessionDataTask:(nullable NSURLSessionDataTask *)sessionDownloadTask;

@end

NS_ASSUME_NONNULL_END
