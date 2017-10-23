//
//  NSString+ZWUtility.h
//  WebBrowser
//
//  Created by Null on 2017/1/7.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ZWUtility)

- (BOOL)isValidURL;
- (BOOL)isLocal;
- (NSString *)ellipsizeWithMaxLength:(NSInteger)maxLength;
- (NSDictionary *)getWebViewJSONDicWithPrefix:(NSString *)prefix;

@end
