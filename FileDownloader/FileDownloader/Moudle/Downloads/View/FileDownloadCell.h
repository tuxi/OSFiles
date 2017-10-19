//
//  FileDownloadCell.h
//  DownloaderManager
//
//  Created by xiaoyuan on 2017/6/5.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+XYConfigure.h"

@class FileDownloadOperation;

@interface FileDownloadCell : UITableViewCell

@property (nonatomic, strong) FileDownloadOperation *downloadItem;

- (void)setLongPressGestureRecognizer:(void (^)(UILongPressGestureRecognizer *longPres))block;

@end
