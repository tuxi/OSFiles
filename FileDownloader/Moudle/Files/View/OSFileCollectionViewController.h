//
//  OSFileCollectionViewController.h
//  FileDownloader
//
//  Created by Swae on 2017/10/28.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@class OSFileAttributeItem;

@interface OSFileCollectionViewController : UIViewController <QLPreviewControllerDataSource>

/// 通过文件目录路径，读取里面所有的文件并展示
- (instancetype)initWithRootDirectory:(NSString *)path;
/// 展示指定的文件目录
- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray;

@property (nonatomic, strong) NSString *rootDirectory;
@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;
@property (nonatomic, assign) BOOL displayHiddenFiles;

@end
