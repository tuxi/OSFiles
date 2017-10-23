//
//  WebViewHistoryItem.h
//  WebBrowser
//
//  Created by Null on 2017/3/15.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebViewHistoryItem : NSObject

@property (nonatomic, copy, readonly) NSString *URLString;
@property (nonatomic, copy, readonly) NSString *title;

- (instancetype)initWithURLString:(NSString *)URLString title:(NSString *)title;

@end
