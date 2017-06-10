//
//  NSObject+XYProperties.h
//  MVVMDemo
//
//  Created by Ossey on 17/2/9.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XYViewModelProtocol.h"
#import "XYViewManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef _Nonnull id (^ViewModelBlock)();


@interface NSObject (XYProperties)


@property (nonatomic, copy, nonnull) ViewModelBlock viewModelBlock;

/// 获取一个对象的所有属性
- (nullable NSDictionary *)xy_allProperties;


@property (nullable, nonatomic, weak) id<XYViewManagerProtocol> viewMangerDelegate;



@property (nullable, nonatomic, weak) id<XYViewModelProtocol> viewModelDelegate;


@end

NS_ASSUME_NONNULL_END
