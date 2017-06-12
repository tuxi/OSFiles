//
//  NSObject+XYProperties.h
//  MVVMDemo
//
//  Created by mofeini on 17/2/9.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYViewModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef _Nonnull id (^ViewModelBlock)();


@interface NSObject (XYProperties)


@property (nonatomic, copy, nonnull) ViewModelBlock viewModelBlock;


- (nullable NSDictionary *)xy_allProperties;


@property (nullable, nonatomic, weak) id<XYViewModelProtocol> viewModelDelegate;


@end

NS_ASSUME_NONNULL_END
