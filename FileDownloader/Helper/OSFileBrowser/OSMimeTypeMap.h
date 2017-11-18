//
//  OSMimeTypeMap.h
//  FileDownloader
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSMimeTypeMap : NSObject

+ (NSString *)mimeTypeForExtension:(NSString *)extension;
+ (NSString *)extensionForMimeType:(NSString *)mimeType;

@end
