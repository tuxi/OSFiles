//
//  NetworkTypeUtils.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "NetworkTypeUtils.h"
#import "AFNetworkReachabilityManager.h"

@implementation NetworkTypeUtils

+ (void)judgeNetworkType:(void (^)(NetworkType type))networkType {
    __block __weak AFNetworkReachabilityManager * manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
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
            if (networkType) {
                networkType(type);
            }
        });
    }];
}


@end
