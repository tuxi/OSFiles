//
//  OSFileItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloadProgress.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OSFileDownloadStatus) {
    OSFileDownloadStatusNotStarted = 0,
    OSFileDownloadStatusStarted,
    OSFileDownloadStatusSuccess,
    OSFileDownloadStatusPaused,
    OSFileDownloadStatusCancelled,
    OSFileDownloadStatusInterrupted,
    OSFileDownloadStatusFailure
};

@interface OSFileItem : NSObject


@property (nonatomic, strong, readonly) NSString *urlPath;
@property (nonatomic, strong) NSURL *localFileURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, assign) OSFileDownloadStatus status;
@property (nonatomic, strong) OSDownloadProgress *progressObj;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, strong) NSArray<NSString *> *downloadErrorMessagesStack;
@property (nonatomic, assign) NSInteger lastHttpStatusCode;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *MIMEType;

- (instancetype)initWithURL:(NSString *)urlPath NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
