//
//  NSURL+ZWUtility.h
//  WebBrowser
//
//  Created by Null on 2017/2/18.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ZWUtility)

- (BOOL)isErrorPageURL;
- (NSURL *)originalURLFromErrorURL;
- (BOOL)isLocal;

@end
