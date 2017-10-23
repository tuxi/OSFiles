//
//  HTTPClient+SearchSug.h
//  WebBrowser
//
//  Created by Null on 2016/11/14.
//  Copyright © 2016年 Null. All rights reserved.
//

#import "HTTPClient.h"

@interface HTTPClient (SearchSug)

- (NSURLSessionDataTask *)getSugWithKeyword:(NSString *)keyword success:(HttpClientSuccessBlock)success fail:(HttpClientFailureBlock)fail;

@end
