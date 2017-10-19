//
//  FileDownloadCell.h
//  DownloaderManager
//
//  Created by xiaoyuan on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+XYConfigure.h"

@class FileItem;

@interface FileDownloadCell : UITableViewCell

@property (nonatomic, strong) FileItem *fileItem;

- (void)setLongPressGestureRecognizer:(void (^)(UILongPressGestureRecognizer *longPres))block;

@end
