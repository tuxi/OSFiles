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

@interface OSFileCollectionViewController : UIViewController <QLPreviewControllerDataSource, UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithRootDirectory:(NSString *)path;

@property (nonatomic, strong) NSString *rootDirectory;
@property (nonatomic, strong) NSArray<OSFileAttributeItem *> *files;
@property (nonatomic, assign) BOOL displayHiddenFiles;

@end
