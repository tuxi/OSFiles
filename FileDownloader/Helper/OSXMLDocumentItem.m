//
//  OSXMLDocumentItem.m
//  ParseHTMLDemo
//
//  Created by Swae on 2017/11/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSXMLDocumentItem.h"
#import <Ono.h>

@interface OSXMLDocumentItem () {
    NSURL *_currentURL;
    NSString *_htmlString;
    dispatch_group_t _group;
    dispatch_queue_t _parseQueue;
    OSXMLElemenParseCompletion _parseXMLElemenCompletionHandler;
}

@end

@implementation OSXMLDocumentItem

+ (instancetype)parseElementWithURL:(NSURL *)url parseCompletion:(OSXMLElemenParseCompletion)completion {
    
    OSXMLDocumentItem *item = [[self alloc] initWithURL:url];;
    item->_parseXMLElemenCompletionHandler = completion;
    return item;
}

+ (instancetype)parseElementWithHTMLString:(NSString *)htmlString parseCompletion:(OSXMLElemenParseCompletion)completion {
    OSXMLDocumentItem *item = [[self alloc] initWithHtmlString:htmlString];
    item->_parseXMLElemenCompletionHandler = completion;
    return item;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _currentURL = url;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithHtmlString:(NSString *)htmlString {
    if (self = [super init]) {
        _htmlString = htmlString;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _group = dispatch_group_create();
    _parseQueue = dispatch_queue_create("com.ossey.OSXMLDocumentItem", DISPATCH_QUEUE_CONCURRENT);
    [self parseVideoURLsByURL];
    [self parseVideoURLsByHTMLString];
    [self parseImageURLsByURL];
    [self parseImageURLsByHTMLString];
    dispatch_group_notify(_group, _parseQueue, ^{
        if (_parseXMLElemenCompletionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _parseXMLElemenCompletionHandler(self.videoURLs, self.imageURLs);
            });
        }
    });
    
}

/// 根据UR串提取HTML中的视频
- (void)parseVideoURLsByURL {
    if (!_currentURL) {
        return;
    }
    
    dispatch_group_enter(_group);
    dispatch_async(_parseQueue, ^{
        NSData *data= [NSData dataWithContentsOfURL:_currentURL];
        
        NSError *error;
        ONOXMLDocument *doc= [ONOXMLDocument HTMLDocumentWithData:data error:&error];
        if (error || !doc) {
            dispatch_group_leave(_group);
            return;
        }
        
        self.videoURLs = [self __parseVideoURLsWithDocument:doc];
        dispatch_group_leave(_group);
    });
    
}

/// 根据HTML字符串提取HTML中的视频
- (void)parseVideoURLsByHTMLString {
    if (!_htmlString.length) {
        return;
    }
    
    dispatch_group_enter(_group);
    dispatch_async(_parseQueue, ^{
        NSError *error;
        ONOXMLDocument *doc= [ONOXMLDocument HTMLDocumentWithString:_htmlString encoding:NSUTF8StringEncoding error:&error];
        if (error || !doc) {
            dispatch_group_leave(_group);
            return;
        }
        
        self.videoURLs = [self __parseVideoURLsWithDocument:doc];
        dispatch_group_leave(_group);
    });
    
}

/// 根据url提取网页中的图片
- (void)parseImageURLsByURL {
    if (!_currentURL) {
        return;
    }
    
    dispatch_group_enter(_group);
    dispatch_async(_parseQueue, ^{
        NSData *data = [NSData dataWithContentsOfURL:_currentURL];
        
        NSError *error;
        ONOXMLDocument *doc= [ONOXMLDocument HTMLDocumentWithData:data error:&error];
        if (error || !doc) {
            dispatch_group_leave(_group);
            return;
        }
        
        self.imageURLs = [self __parseImageURLsWithDocument:doc];
        dispatch_group_leave(_group);
    });
    
}

/// 根据HTML字符串提取HTML中的图片
- (void)parseImageURLsByHTMLString {
    if (!_htmlString.length) {
        return;
    }
    
    dispatch_group_enter(_group);
    dispatch_async(_parseQueue, ^{
        NSError *error;
        ONOXMLDocument *doc = [ONOXMLDocument HTMLDocumentWithString:_htmlString encoding:NSUTF8StringEncoding error:&error];
        if (error || !doc) {
            dispatch_group_leave(_group);
            return;
        }
        self.imageURLs = [self __parseImageURLsWithDocument:doc];
        
        dispatch_group_leave(_group);
    });
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////
- (NSArray *)__parseVideoURLsWithDocument:(ONOXMLDocument *)doc {
    NSMutableArray *videoURLs = [NSMutableArray array];
    
    // 解析普通网站的HTML，提取子节点tag为video的url, baidu
    [doc enumerateElementsWithXPath:@".//div" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        /// 提取每个子节点的图片img
        NSArray *videoArray = [element childrenWithTag:@"video"];
        [videoArray enumerateObjectsUsingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *video = [element valueForAttribute:@"src"];
            if (video.length) {
                // 如果不是完整路径就拼接完成路径
                if ([video hasPrefix:@"https"] || [video hasPrefix:@"http"]) {
                    [videoURLs addObject:video];
                }
            }
        }];
        
    }];
    
    // 应盆友请求😆：此解析主要用于提取"https://www.8863h.com/Html/110/index-3.html"中的视频
    [doc enumerateElementsWithXPath:@".//ul[@class='downurl']/a" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        
        ///
        NSString *downurl = [element valueForAttribute:@"href"];
        if ([downurl hasPrefix:@"https"] || [downurl hasPrefix:@"http"]) {
            [videoURLs addObject:downurl];
        }
    }];
    
    return videoURLs;
}

- (NSArray *)__parseImageURLsWithDocument:(ONOXMLDocument *)doc {
    NSMutableArray *imageURLs= [NSMutableArray array];
    [doc enumerateElementsWithXPath:@".//div" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        /// 提取每个子节点的图片img
        NSArray *imgArr = [element childrenWithTag:@"img"];
        [imgArr enumerateObjectsUsingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *img = [element valueForAttribute:@"src"];
            if (img.length) {
                // 如果不是完整路径就拼接完成路径
                if ([img hasPrefix:@"https"] || [img hasPrefix:@"http"]) {
                    [imageURLs addObject:img];
                }
            }
        }];
        
    }];
    
    // 解析http://www.ugirls.com/Shop/Detail/Product-392.html中的img
    [doc enumerateElementsWithXPath:@".//div[@class='zhu_img']/a/img" usingBlock:^(ONOXMLElement *element, NSUInteger idx, BOOL *stop) {
        
        ///
        NSString *downurl = [element valueForAttribute:@"src"];
        if ([downurl hasPrefix:@"https"] || [downurl hasPrefix:@"http"]) {
            [imageURLs addObject:downurl];
        }
    }];
    
    return imageURLs;
}

/*
 /// 获取HTML中的图片
 - (void)getImgsFormHTML:(void (^)(NSArray *imageURLs))completion {
 if (!completion) {
 return;
 }
 NSMutableArray *arrImgURL = [[NSMutableArray alloc] init];
 NSInteger imageCount = [self nodeCountOfTag:@"img"];
 if (!imageCount) {
 [self xy_showMessage:@"未找到文件"];
 }
 else {
 for (int i = 0; i < imageCount; i++) {
 //         NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('video')[%d].src", i];
 NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('img')[%d].src", i];
 [self.browserContainerView.webView evaluateJavaScript:jsString completionHandler:^(NSString *str, NSError *error) {
 
 if (error ==nil && str.length) {
 [arrImgURL addObject:str];
 }
 if (i == imageCount-1) {
 completion(arrImgURL);
 }
 }];
 }
 }
 
 }
 
 /// 获取HTML中的视频
 - (void)getVideosFormHTML:(void (^)(NSArray *videoURLs))completion {
 if (!completion) {
 return;
 }
 NSMutableArray *videoURLs = [[NSMutableArray alloc] init];
 NSInteger videoCount = [self nodeCountOfTag:@"video"];
 if (!videoCount) {
 // 通过class去查找
 OSXMLDocumentItem *parseItem = [OSXMLDocumentItem parseElementWithHTMLString:[self getCurrentPageHTMLString]];
 if (parseItem.videoURLs.count) {
 completion(parseItem.videoURLs);
 }
 else {
 [self xy_showMessage:@"未找到文件"];
 
 }
 
 }
 else {
 for (int i = 0; i < videoCount; i++) {
 //         NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('video')[%d].src", i];
 NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('video')[%d].src", i];
 [self.browserContainerView.webView evaluateJavaScript:jsString completionHandler:^(NSString *str, NSError *error) {
 
 if (error == nil && str.length) {
 [videoURLs addObject:str];
 }
 if (i == videoCount - 1) {
 completion(videoURLs);
 }
 }];
 }
 }
 
 }
 
 /// 通过标签名来获得当前网页中的元素对象的，而且它返回的是一个数组，因为tag相同的元素可能不止一个, 所有返回的是数组
 - (NSInteger)nodeCountOfTag:(NSString *)tag {
 
 NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('%@').length", tag];
 
 int count =  [[self.browserContainerView.webView stringByEvaluatingJavaScriptFromString:jsString] intValue];
 
 return count;
 }
 
 /// 通过元素的id属性来获得当前网页中的元素对象的，
 /// 由于在一个文档中相同id名称的元素只能有一个，所以它返回的就是一个对象
 //- (NSInteger)nodeCountOfId:(NSString *)idString {
 //
 //    NSString *jsString = [NSString stringWithFormat:@"document.getElementById('%@')", idString];
 //
 //    id count =  [self.browserContainerView.webView stringByEvaluatingJavaScriptFromString:jsString];
 //
 //    return count;
 //}
 
 /// 通过标签名来获得当前网页中的元素对象的，而且它返回的是一个数组，因为tag相同的元素可能不止一个, 所有返回的是数组
 - (NSInteger)nodeCountOfClass:(NSString *)className {
 
 NSString *jsString = [NSString stringWithFormat:@"document.getElementsByClassName('%@').length", className];
 
 int count =  [[self.browserContainerView.webView stringByEvaluatingJavaScriptFromString:jsString] intValue];
 
 return count;
 }

 
 */

@end


