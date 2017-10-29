//
//  OSFileAttributeItem.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFile.h"

@interface OSFileAttributeItem : OSFile

@property (nonatomic, copy) NSString *fullPath;
@property (nonatomic, assign) NSUInteger subFileCount;

@end
