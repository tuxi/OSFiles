//
//  OSFileItem.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSDownloadProgress.h"
#import "OSDownloaderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OSFileItem : NSObject <OSDownloadFileItemProtocol>

@property (nonatomic, copy) void (^downloadStatusBlock)(OSFileDownloadStatus state);

- (instancetype)initWithURL:(NSString *)urlPath NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
