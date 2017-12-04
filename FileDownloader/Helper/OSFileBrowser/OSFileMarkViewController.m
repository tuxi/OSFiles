//
//  OSFileMarkViewController.m
//  FileDownloader
//
//  Created by swae on 2017/12/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileMarkViewController.h"
#import "OSFileCollectionViewCell.h"
#import "OSFileAttributeItem.h"

@interface OSFileMarkViewController ()

@end

@implementation OSFileMarkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markupFileCompletion:) name:OSFileCollectionViewControllerDidMarkupFileNotification object:nil];
}

- (void)markupFileCompletion:(NSNotification *)notification {
   
    NSString *filePath = notification.object;
    if ([filePath isKindOfClass:[NSString class]]) {
        OSFileAttributeItem *file = [[OSFileAttributeItem alloc] initWithPath:filePath error:nil];
        if (file) {
            NSMutableArray *array = self.files.mutableCopy;
            [array insertObject:file atIndex:0];
            self.files = array.copy;
            [self reloadCollectionData];
        }
    }
}

/// 重新父类方法
- (NSArray *)bottomHUDTitles {
    return @[
             @"全选",
             @"复制",
             @"移动",
             @"删除",
             ];
}



@end
