//
//  HTTPClient.h
//  ZhihuDaily
//
//  Created by Null on 16/8/3.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTTPManager;
@class BaseResponseModel;

typedef void (^HttpClientSuccessBlock)(NSURLSessionDataTask *task, BaseResponseModel *model);
typedef void (^HttpClientImageSuccessBlock)(UIImage *image, NSError *error);
typedef void (^HttpClientFailureBlock)(NSURLSessionDataTask *task, BaseResponseModel *model);

@interface HTTPClient : NSObject

@property (nonatomic, strong, readonly) HTTPManager *httpManager;

SYNTHESIZE_SINGLETON_FOR_CLASS_HEADER(HTTPClient)

- (void)getImageWithURL:(NSURL *)url completion:(HttpClientImageSuccessBlock)completion;

@end
