//
//  OSFileCollectionViewController.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSFilePreviewViewController.h"

FOUNDATION_EXPORT NSNotificationName const OSFileCollectionViewControllerOptionFileCompletionNotification;
FOUNDATION_EXPORT NSNotificationName const OSFileCollectionViewControllerOptionSelectedFileForCopyNotification;
FOUNDATION_EXPORT NSNotificationName const OSFileCollectionViewControllerOptionSelectedFileForMoveNotification;

typedef NS_ENUM(NSInteger, OSFileCollectionViewControllerMode) {
    OSFileCollectionViewControllerModeDefault, // 默认模式
    OSFileCollectionViewControllerModeEdit,    // 编辑模式
    OSFileCollectionViewControllerModeCopy,    // 复制模式，此控制器的rootDirectory为最终复制的目录
    OSFileCollectionViewControllerModeMove,    // 移动模式，此控制器的rootDirectory为最终移动的目录
    
};


@class OSFileAttributeItem, OSFileCollectionViewController;

/// 操作文件的协议
@protocol OSFileCollectionViewControllerFileOptionDelegate <NSObject>

@optional
/// 即将操作文件时调用, 代理实现此方法，可以自定义跳转， 如果执行此方法则不执行desDirectorsForOption:selectedFiles:fileCollectionViewController:
/// @param fileCollectionViewController 当前控制器
/// @param selectedFiles 用户已选中的文件，需要移动的文件
/// @param mode 操作方式，mode 操作的模式，可能是移动或复制
- (void)fileCollectionViewController:(OSFileCollectionViewController *)fileCollectionViewController selectedFiles:(NSArray<OSFileAttributeItem *> *)selectedFiles optionMode:(OSFileCollectionViewControllerMode)mode;

/// 获取目录列表, 选中的文件操作时调用,
/// @param mode 操作的模式，可能是移动或复制
/// @param selectedFiles 已选中的文件
/// @param fileCollectionViewController 当前控制器，非即将跳转的控制器
/// @return 返回目标文件目录列表
- (NSArray<NSString *> *)desDirectorsForOption:(OSFileCollectionViewControllerMode)mode selectedFiles:(NSArray<OSFileAttributeItem *> *)selectedFiles fileCollectionViewController:(OSFileCollectionViewController *)fileCollectionViewController;

@end

@interface OSFileCollectionViewController : UIViewController <QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;
@property (nonatomic, assign) BOOL hideDisplayFiles;
/// 用于操作文件的全局代理，对整个类有效
@property (nonatomic, class) id<OSFileCollectionViewControllerFileOptionDelegate> fileOperationDelegate;
/// 当前控制器是否用于展示标记
@property (nonatomic, assign) BOOL displayMarkupFiles;

/// 通过文件目录路径，读取里面所有的文件并展示
- (instancetype)initWithRootDirectory:(NSString *)path;
/// 通过文件目录路径，读取里面所有的文件并展示, 传入当前控制器的模式
- (instancetype)initWithRootDirectory:(NSString *)path controllerMode:(OSFileCollectionViewControllerMode)mode;
/// 展示指定的文件目录
- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray;
- (instancetype)initWithDirectoryArray:(NSArray *)directoryArray controllerMode:(OSFileCollectionViewControllerMode)mode;;

/// 拷贝文件到指定目录
- (void)copyFiles:(NSArray<OSFileAttributeItem *> *)fileItems
  toRootDirectory:(NSString *)rootPath
completionHandler:(void (^)(void))completion;

/// 重新加载本地文件，并刷新
- (void)reloadFilesWithCallBack:(void (^)(void))callBack;
- (void)reloadFiles;
/// 刷新已读取的文件
- (void)reloadCollectionData;

/// 通过当前控制器查看indexPath对应的子文件
/// @param viewController 展示文件的控制器对象
/// @param indexPath 当前目录下的子文件
- (void)showDetailController:(UIViewController *)viewController atIndexPath:(NSIndexPath *)indexPath;
/// 根据indexPath获取当前文件目录中的子文件，并创建对象的控制器返回
- (UIViewController *)previewControllerByIndexPath:(NSIndexPath *)indexPath;
- (UIViewController *)previewControllerWithFilePath:(NSString *)filePath;
- (void)showDetailController:(UIViewController *)viewController parentPath:(NSString *)parentPath;
/// 根据文件路径获取一个OSFileAttributeItem，如果当前控制器的files数组中有就会返回，没有就会创建一个OSFileAttributeItem对象
- (OSFileAttributeItem *)getFileItemByPath:(NSString *)path;
@end

