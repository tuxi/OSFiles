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
}

- (void)markupFileCompletion:(NSNotification *)notification {
   
    OSFileAttributeItem *file = notification.object;
    if (![file isKindOfClass:[OSFileAttributeItem class]]) {
        return;
    }
    NSDictionary *info = notification.userInfo;
    BOOL isCancelMark = [info[@"isCancelMark"] boolValue];
    if (!isCancelMark) {
        if (file) {
            NSMutableArray *array = self.files.mutableCopy;
            [array insertObject:file atIndex:0];
            self.files = array.copy;
        }
    }
    else {
        NSUInteger foundIdx = [self.files indexOfObjectPassingTest:^BOOL(OSFileAttributeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL res = [obj isEqualToFile:file];
            if (res) {
                *stop = YES;
            }
            return res;
        }];
        if (self.files && foundIdx != NSNotFound) {
            NSMutableArray *files = self.files.mutableCopy;
            [files removeObjectAtIndex:foundIdx];
            self.files = files;
        }
    }
    [self reloadCollectionData];
    
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
