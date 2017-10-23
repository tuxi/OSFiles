//
//  HTTPClient+SearchSug.m
//  WebBrowser
//
//  Created by Null on 2016/11/14.
//  Copyright © 2016年 Null. All rights reserved.
//

#import "HTTPClient+SearchSug.h"
#import "HTTPURLConfiguration.h"
#import "HTTPManager.h"
#import "BaiduSugResponseModel.h"

@implementation HTTPClient (SearchSug)

- (NSURLSessionDataTask *)getSugWithKeyword:(NSString *)keyword success:(HttpClientSuccessBlock)success fail:(HttpClientFailureBlock)fail{
    NSString *relativePath = [[HTTPURLConfiguration sharedInstance] baiduURLWithPath:keyword];
    
    return [self.httpManager GET:relativePath parameters:nil modelClass:[BaiduSugResponseModel class] success:success failure:fail];
}

@end
