//
//  NetworkTypeUtils.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NetworkType) {
    NetworkTypeUnknown = -1,
    NetworkTypeNotReachable = 0,
    NetworkTypeWWAN = 1,
    NetworkTypeWIFI = 2,
};


@interface NetworkTypeUtils : NSObject

+ (void)judgeNetworkType:(void (^)(NetworkType type))networkType;

@end
