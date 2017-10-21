//
//  NSObject+XYRequest.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "NSObject+XYRequest.h"
#import <objc/runtime.h>

@implementation NSObject (XYRequest)

- (NSString *)xy_scheme {
    return objc_getAssociatedObject(self, @selector(xy_scheme));
}

- (void)setXy_scheme:(NSString *)xy_scheme {
    objc_setAssociatedObject(self, @selector(xy_scheme), xy_scheme, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)xy_host {
    return objc_getAssociatedObject(self, @selector(xy_host));
}

- (void)setXy_host:(NSString *)xy_host {
    objc_setAssociatedObject(self, @selector(xy_host), xy_host, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)xy_path {
    return objc_getAssociatedObject(self, @selector(xy_path));
}

- (void)setXy_path:(NSString *)xy_path {
    objc_setAssociatedObject(self, @selector(xy_path), xy_path, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)xy_url {
    return objc_getAssociatedObject(self, @selector(xy_url));
}

- (void)setXy_url:(NSString *)xy_url {
    objc_setAssociatedObject(self, @selector(xy_url), xy_url, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (RequestMethod)xy_method {
    return [objc_getAssociatedObject(self, @selector(xy_method)) integerValue];
}

- (void)setXy_method:(RequestMethod)xy_method {
    objc_setAssociatedObject(self, @selector(xy_method), @(xy_method), OBJC_ASSOCIATION_ASSIGN);
}

- (id)xy_params {
    return objc_getAssociatedObject(self, @selector(xy_params));
}
- (void)setXy_params:(id)xy_params {
    objc_setAssociatedObject(self, @selector(xy_params), xy_params, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (XYRequestFileConfig *)xy_fileConfig {
    return objc_getAssociatedObject(self, @selector(xy_fileConfig));
}
- (void)setXy_fileConfig:(XYRequestFileConfig *)xy_fileConfig {
    return objc_setAssociatedObject(self, @selector(xy_fileConfig), xy_fileConfig, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setXy_headers:(NSDictionary *)xy_headers {
    objc_setAssociatedObject(self, @selector(xy_headers), xy_headers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSDictionary *)xy_headers {
    return objc_getAssociatedObject(self, @selector(xy_headers));
}

- (void)setXy_fileConfigList:(NSArray<XYRequestFileConfig *> *)xy_fileConfigList {
    objc_setAssociatedObject(self, @selector(xy_fileConfigList), xy_fileConfigList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<XYRequestFileConfig *> *)xy_fileConfigList {
    return objc_getAssociatedObject(self, @selector(xy_fileConfigList));
}

- (RequestDataType)requestType {
    return [objc_getAssociatedObject(self, @selector(requestType)) integerValue];
}

- (void)setRequestType:(RequestDataType)requestType {
    objc_setAssociatedObject(self, @selector(requestType), @(requestType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
