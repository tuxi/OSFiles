//
//  NSObject+XYRequest.h
//  MVVMDemo
//
//  Created by Ossey on 17/2/10.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, RequestMethod) {
    RequestMethodGET,
    RequestMethodPOST,
    RequestMethodUPLOAD,
    RequestMethodDOWNLOAD
    
};

typedef NS_ENUM(NSInteger, RequestDataType) {
    RequestDataTypeMore,
    RequestDataTypeNew,
};

@class XYRequestFileConfig;

@interface NSObject (XYRequest)

/// scheme 请求协议(eg: http, https, ftp)
@property (nonatomic, copy, nonnull) NSString *xy_scheme;

/// host
@property (nonatomic, copy, nonnull) NSString *xy_host;

/// path
@property (nonatomic, copy, nonnull) NSString *xy_path;

/// 请求头 此参数需要设置在requestSerializer中
@property (nonatomic, strong, nonnull) NSDictionary *xy_headers;

/// method 请求方法
@property (nonatomic, assign) RequestMethod xy_method;

/// url 请求的全路径 (如果设置了url，则不需要在设置scheme，host，path 属性)
@property (nonatomic, copy) NSString *xy_url;

/// parameters 请求参数
@property (nonatomic, strong) id xy_params;

/// 单个文件上传
@property (nonatomic, strong) XYRequestFileConfig *xy_fileConfig;

/// xy_fileConfigList集合，当有多个时，就是有多个文件要上传,当使用了此属性时，就不要使用xy_fileConfig啦
@property (nonatomic, strong) NSArray<XYRequestFileConfig *> *xy_fileConfigList;

/// 请求数据的类型是，请求最新的数据，还是加载更多
@property (nonatomic, assign) RequestDataType requestType;

@end

NS_ASSUME_NONNULL_END
