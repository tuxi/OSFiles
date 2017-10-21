//
//  NSObject+XYProperties.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/9.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "NSObject+XYProperties.h"
#import <objc/runtime.h>

@implementation NSObject (XYProperties)

- (id<XYViewModelProtocol>)viewModelDelegate {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setViewModelDelegate:(id<XYViewModelProtocol>)viewModelDelegate {
    objc_setAssociatedObject(self, @selector(viewModelDelegate), viewModelDelegate, OBJC_ASSOCIATION_ASSIGN);
}


- (ViewMangerInfosBlock)viewMangerInfosBlock {
    return objc_getAssociatedObject(self, @selector(viewMangerInfosBlock));
}

- (void)setViewMangerInfosBlock:(ViewMangerInfosBlock)viewMangerInfosBlock {
    objc_setAssociatedObject(self, @selector(viewMangerInfosBlock), viewMangerInfosBlock, OBJC_ASSOCIATION_COPY);
}

- (ViewModelInfosBlock)viewModelInfosBlock {
    return objc_getAssociatedObject(self, @selector(viewModelInfosBlock));
}

- (void)setViewModelInfosBlock:(ViewModelInfosBlock)viewModelInfosBlock {
    objc_setAssociatedObject(self, @selector(viewModelInfosBlock), viewModelInfosBlock, OBJC_ASSOCIATION_COPY);
}

- (ViewModelBlock)viewModelBlock {
    return objc_getAssociatedObject(self, @selector(viewModelBlock));
}

- (void)setViewModelBlock:(ViewModelBlock)viewModelBlock {
    objc_setAssociatedObject(self, @selector(viewModelBlock), viewModelBlock, OBJC_ASSOCIATION_COPY);
}


- (void)setXy_viewMangerInfos:(NSDictionary *)xy_viewMangerInfos {
    objc_setAssociatedObject(self, @selector(xy_viewMangerInfos), xy_viewMangerInfos, OBJC_ASSOCIATION_COPY);
}
- (NSDictionary *)xy_viewMangerInfos {
    return objc_getAssociatedObject(self, @selector(xy_viewMangerInfos));
}

- (void)setXy_viewModelInfos:(NSDictionary *)xy_viewModelInfos {
    objc_setAssociatedObject(self, @selector(xy_viewModelInfos), xy_viewModelInfos, OBJC_ASSOCIATION_COPY);
}
- (NSDictionary *)xy_viewModelInfos {
    return objc_getAssociatedObject(self, @selector(xy_viewModelInfos));
}

- (nullable NSDictionary *)xy_allProperties
{
    unsigned int count = 0;
    
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    NSMutableDictionary *resultDict = [@{} mutableCopy];
    
    for (NSUInteger i = 0; i < count; i ++) {
        
        const char *propertyName = property_getName(properties[i]);
        NSString *name = [NSString stringWithUTF8String:propertyName];
        id propertyValue = [self valueForKey:name];
        
        if (propertyValue) {
            resultDict[name] = propertyValue;
        } else {
            resultDict[name] = @"";
            resultDict[name] = @"字典的key对应的value不能为nil";
        }
    }
    
    free(properties);
    
    return resultDict;
}

@end
