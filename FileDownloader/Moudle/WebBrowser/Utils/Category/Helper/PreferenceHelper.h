//
//  PreferenceHelper.h
//  WebBrowser
//
//  Created by Null on 2017/2/14.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const KeyNoImageModeStatus;
extern NSString * const KeyPasteboardURL;

@interface PreferenceHelper : NSObject

+ (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
+ (void)setURL:(NSURL *)url forKey:(NSString *)defaultName;

+ (BOOL)boolForKey:(NSString *)defaultName;
+ (NSURL *)URLForKey:(NSString *)defaultName;

@end
