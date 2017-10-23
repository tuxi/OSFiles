//
//  NSData+ZWUtility.m
//  WebBrowser
//
//  Created by Null on 2017/9/25.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "NSData+ZWUtility.h"

@implementation NSData (ZWUtility)

- (NSString *)jsonString{
    return [[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end
