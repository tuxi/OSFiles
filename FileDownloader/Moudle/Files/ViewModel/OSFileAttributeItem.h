//
//  OSFileAttributeItem.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
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

@property (nonatomic, copy) NSString *fullPath;
@property (nonatomic, assign) NSUInteger subFileCount;
@property (nonatomic, assign) OSFileAttributeItemStatus status;

@end
