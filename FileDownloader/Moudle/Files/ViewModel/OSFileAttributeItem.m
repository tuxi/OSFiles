//
//  OSFileAttributeItem.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileAttributeItem.h"

@implementation OSFileAttributeItem

- (instancetype)initWithPath:(NSString *)filePath {
    if (self = [super initWithPath:filePath]) {
        self.fullPath = filePath;
    }
    return self;
}

@end
