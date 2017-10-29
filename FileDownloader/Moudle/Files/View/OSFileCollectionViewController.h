//
//  OSFileCollectionViewController.h
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

typedef NS_ENUM(NSInteger, OSFileCollectionViewControllerMode) {
    OSFileCollectionViewControllerModeDefault, // 默认模式
    OSFileCollectionViewControllerModeEdit,    // 编辑模式
    OSFileCollectionViewControllerModeCopy,    // 复制模式，若是此种类型，此控制器的rootDirectory为最终复制的目录
    
};

@class OSFileAttributeItem;

@interface OSFileCollectionViewController : UIViewController <QLPreviewControllerDataSource>

/// 通过文件目录路径，读取里面所有的文件并展示
- (instancetype)initWithRootDirectory:(NSString *)path;
/// 通过文件目录路径，读取里面所有的文件并展示, 传入当前控制器的模式
- (instancetype)initWithRootDirectory:(NSString *)path controllerMode:(OSFileCollectionViewControllerMode)mode;
/// 展示指定的文件目录
- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray;
- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray controllerMode:(OSFileCollectionViewControllerMode)mode;;

@property (nonatomic, strong) NSString *rootDirectory;
@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;
@property (nonatomic, assign) BOOL displayHiddenFiles;

@end
