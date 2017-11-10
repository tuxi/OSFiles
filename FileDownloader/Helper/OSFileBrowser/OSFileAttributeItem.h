//
//  OSFileAttributeItem.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFile.h"

typedef NS_ENUM(NSInteger, OSFileAttributeItemStatus) {
    /// 默认状态
    OSFileAttributeItemStatusDefault,
    /// 编辑状态
    OSFileAttributeItemStatusEdit,
    /// 被标记状态
    OSFileAttributeItemStatusChecked
};

@interface OSFileAttributeItem : OSFile

@property (nonatomic, assign) OSFileAttributeItemStatus status;

/// 指的是展示在主页的文件夹, 是否是根目录，当是根目录时不允许编辑
@property (nonatomic, assign) BOOL isRootDirectory;

- (BOOL)isDownloadBrowser;

@end

