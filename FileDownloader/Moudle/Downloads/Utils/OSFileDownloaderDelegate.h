//
//  OSFileDownloaderDelegate.h
//  OSFileDownloader
//
//  Created by Ossey on 2017/7/3.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSFileDownloadProtocol.h"

/*
 此类遵守了OSFileDownloaderDelegate，作为OSFileDownloader的协议实现类
 主要对下载状态的更新、下载进度的更新、发送通知、下载信息的规则
 */


@interface OSFileDownloaderDelegate : NSObject <OSFileDownloaderDelegate>

@end
