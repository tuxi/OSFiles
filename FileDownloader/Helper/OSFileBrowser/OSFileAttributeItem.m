//
//  OSFileAttributeItem.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFileAttributeItem.h"
#import "NSString+OSFile.h"

@implementation OSFileAttributeItem

- (instancetype)initWithPath:(NSString *)filePath hideDisplayFiles:(BOOL)hideDisplayFiles error:(NSError *__autoreleasing *)error {
    if (self = [super initWithPath:filePath hideDisplayFiles:hideDisplayFiles error:error]) {
        _path = filePath;
        self.status = OSFileAttributeItemStatusDefault;
    }
    return self;
}

- (NSString *)displayName {
    if ([self.path isEqualToString:[NSString getDocumentPath]]) {
        return @"iTunes文件";
    }
    else if ([self isDownloadBrowser]) {
        return @"缓存";
    }
    return [super displayName];
}

- (BOOL)isRootDirectory {
    if ([self.path isEqualToString:[NSString getDocumentPath]]) {
        return YES;
    }
    else if ([self.path isEqualToString:[NSString getRootPath]]) {
        return YES;
    }
    return _isRootDirectory;
}

- (BOOL)isDownloadBrowser {
    return [self.path isEqualToString:[NSString getDownloadDisplayFolderPath]];
}

@end

