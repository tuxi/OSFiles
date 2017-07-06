//
//  NetworkTypeUtils.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "NetworkTypeUtils.h"
#import "AFNetworkReachabilityManager.h"

static NetworkType _networkType;

NSString * const NetworkTypeChangeNotification = @"NetworkTypeChangeNotification";

@implementation NetworkTypeUtils

+ (void)load {
    _networkType = NetworkTypeUnknown;
    [self judgeNetworkType:nil];
}

+ (void)judgeNetworkType:(void (^)(NetworkType type))networkType {
    __block __weak AFNetworkReachabilityManager * manager = [AFNetworkReachabilityManager sharedManager];
    
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NetworkType type = NetworkTypeUnknown;
        if (status ==  AFNetworkReachabilityStatusUnknown) {
            type = NetworkTypeUnknown;
        } else if (status == AFNetworkReachabilityStatusNotReachable) {
            type = NetworkTypeNotReachable;
            
        } else if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
            type = NetworkTypeWWAN;
        } else if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
            type = NetworkTypeWIFI;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NetworkTypeChangeNotification         object:nil userInfo:@{@"networkType": @(type)}];
            if (networkType) {
                networkType(type);
            }
        });
        _networkType = type;
    }];
    
    [manager startMonitoring];
}

+ (NetworkType)networkType {
    
    return _networkType;
}

@end
