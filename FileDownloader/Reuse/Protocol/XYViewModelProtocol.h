//
//  XYViewModelProtocol.h
//  MVVMDemo
//
//  Created by mofeini on 17/2/9.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XYNetworkRequest.h"
#import "NSObject+XYRequest.h"


/**
 *  请求成功block
 */
typedef void (^successBlock)(id responseObject);
/**
 *  请求失败block
 */
typedef void (^failureBlock) (NSError *error);
/**
 *  请求响应block
 */
typedef void (^responseBlock)(id dataObj, NSError *error);
/**
 *  监听进度响应block
 */
typedef void (^progressBlock)(NSProgress * progress);
/**
 *  将自己的信息返回给ViewManger的block
 */
typedef void (^ViewMangerInfosBlock)();
/**
 *  将自己的信息返回给ViewModel的block
 */
typedef void (^ViewModelInfosBlock)();
/**
 *  配置请求参数的block
 */
typedef void(^RequestItemBlock)(id<XYRequestProtocol> request);


@protocol XYViewModelProtocol <NSObject>


@optional
/**
 *  通知
 */
- (void)xy_notice;

/**
 *  返回指定viewModel的所引用的控制器
 */
- (void)xy_viewModelWithViewController:(UIViewController *)viewController;

/**
 *  加载数据
 */
- (NSURLSessionTask *)xy_viewModelWithProgress:(progressBlock)progress
                                       success:(successBlock)success
                                       failure:(failureBlock)failure;


/**
 * 加载数据
 *
 * @param   requestBlock  通过此block回调一个网络请求对象，配置请求参数
 * @param   progress  请求进度回调
 * @param   success  请求成功回调
 * @return  failure  请求失败回调
 */
- (NSURLSessionTask *)xy_viewModelWithConfigRequest:(RequestItemBlock)requestBlock
                                           progress:(progressBlock)progress
                                            success:(successBlock)success
                                            failure:(failureBlock)failure;

/**
 *  传递模型给view
 */
- (void)xy_viewModelWithModelBlcok:(void (^)(id model))modelBlock;


@end
