//
//  XYNetworkRequest.h
//  MVVMDemo
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//  封装的网络请求工具类

#import <Foundation/Foundation.h>
#import "XYRequestProtocol.h"


/// 请求成功block
typedef void (^successBlock)(id responseObject);

/// 请求失败block
typedef void (^failureBlock) (NSError *error);

/// 请求响应block
typedef void (^responseBlock)(id dataObj, NSError *error);

/// 监听进度响应block
typedef void (^progressBlock)(NSProgress * pgs);

@class XYRequestFileConfig;
@interface XYNetworkRequest : NSObject

/// 请求超时时间
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/// reachable
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/// reachableViaWWAN
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/// reachableViaWiFi
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

/// 初始化实例
+ (instancetype)sharedInstance;

/// 取消所有操作
- (void)cancelAllOperations;

/**
 *  配置全局的scheme和host，若request中重新设置新值，则值为request中设置的新值
 *
 *  @param scheme 传输协议 (eg: http, https, ftp)
 *  @param host   主机地址
 */
- (void)configScheme:(NSString *)scheme host:(NSString *)host;


/**
 * 发送请求Block(在block内部配置request)
 *
 * @param   request  在外部配置request对象,该对象需遵守XYRequestProtocol协议
 * @param   progress  请求进度回调block
 * @param   success  请求成功回调block
 * @return  failure  请求失败回调block
 */
- (NSURLSessionTask *)sendRequest:(id<XYRequestProtocol>)request
                         progress:(progressBlock)progress
                          success:(successBlock)success
                          failure:(failureBlock)failure;

/**
 * 发送请求Block(在block内部配置request)
 *
 * @param   requestBlock  返回一个建好的请求对象，内部可以使用这个request对象请求数据
 * @param   progress  请求进度回调block
 * @param   success  请求成功回调block
 * @return  failure  请求失败回调block
 */
- (NSURLSessionTask *)sendRequestBlock:(id<XYRequestProtocol> (^)())requestBlock
                              progress:(progressBlock)progress
                               success:(successBlock)success
                               failure:(failureBlock)failure;


@end

#pragma mark - 上传文件 配置

@interface XYRequestFileConfig : NSObject<NSCopying>

/// 文件二进制数据
@property (nonatomic, strong) NSData *fileData;

/// 服务器接收的 类似input标签type为file的name值
/// 此参数用于获取文件上传对象 Part part = request.getPart("f"); 这个f就是name的值
/* 
web端，可以这么写，name属性，就是相当于type="file"的name
<form action="/FileUploadDemo/upload1" method="post" enctype="multipart/form-data">
<input type="text" name="username"/><br/>
<input type="file" name="f"/><br/>
<input type="submit" value="提交"/>
</form>
 */
@property (nonatomic, copy) NSString *name;

/// 文件全名，要带上后缀，比如1.png
@property (nonatomic, copy) NSString *fileName;

/// 文件类型
@property (nonatomic, copy) NSString *mimeType;

+ (instancetype)fileConfigWithFormData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

- (instancetype)initWithFormData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

@end
