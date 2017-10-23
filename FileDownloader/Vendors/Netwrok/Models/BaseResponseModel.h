//
//  BaseRespnseModel.h
//  ZhihuDaily
//
//  Created by Null on 16/8/3.
//  Copyright © 2016年 Null. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface BaseResponseModel : MTLModel <MTLJSONSerializing>

@property (assign, readonly, nonatomic) int errorCode;
@property (copy, readonly, nonatomic) NSString *errorMsg;

- (instancetype)initWithErrorCode:(int)errorCode
                         errorMsg:(NSString *)errorMsg;

@end
