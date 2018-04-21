//
//  OSPhoneUtils.h
//  FileDownloader
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSPhoneUtils : NSObject

+ (NSString *)formatPhone:(NSString *)phone forceInternational:(bool)forceInternational;
+ (NSString *)formatPhoneUrl:(NSString *)phone;

+ (NSString *)cleanPhone:(NSString *)phone;
+ (NSString *)cleanInternationalPhone:(NSString *)phone forceInternational:(bool)forceInternational;

@end
