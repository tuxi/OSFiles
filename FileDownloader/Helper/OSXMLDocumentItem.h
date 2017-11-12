//
//  OSXMLDocumentItem.h
//  ParseHTMLDemo
//
//  Created by Swae on 2017/11/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^OSXMLElemenParseCompletion)(NSArray *videoURLs, NSArray *imageURLs);

@interface OSXMLDocumentItem : NSObject

@property (nonatomic, strong) NSArray *videoURLs;
@property (nonatomic, strong) NSArray *imageURLs;

+ (instancetype)parseElementWithURL:(NSURL *)url parseCompletion:(OSXMLElemenParseCompletion)completion;
+ (instancetype)parseElementWithHTMLString:(NSString *)htmlString parseCompletion:(OSXMLElemenParseCompletion)completion;

@end

