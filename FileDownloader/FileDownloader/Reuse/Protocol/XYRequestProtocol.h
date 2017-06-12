//
//  XYRequestProtocol.h
//  MVVMDemo
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol XYRequestProtocol <NSObject>

@optional
/**
 *  配置request请求参数
 *
 *  @return NSDictionary 或者 自定义参数模型
 */
- (NSDictionary *)xy_requestParameters;


@required
/**
 *  配置request的路径、请求参数、requestSerializer等
 */
- (void)xy_requestConfigures;


@end
