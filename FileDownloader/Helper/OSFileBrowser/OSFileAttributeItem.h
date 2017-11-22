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

/// 当在某个页面修改collectionView的排列布局后，只是把当前显示的cell的布局更新了，
/// 那些没有显示的cell并未修改，所以在这里标注下，当修改完成后就设置为NO
@property (nonatomic, assign) BOOL needReLoyoutItem;

/// 显示带有富文本的文件名称
@property (nonatomic, copy) NSMutableAttributedString *displayNameAttributedText;

- (BOOL)isDownloadBrowser;
- (BOOL)isICloudDrive;

@end

