//
//  DownloadsTableViewModel.h
//  OSFileDownloader
//
//  Created by alpface on 2017/6/12.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "BaseTableViewModel.h"
#import "OSFileDownloadCell.h"

@interface DownloadsTableViewModel : BaseTableViewModel

- (OSFileDownloadCell *)getDownloadCellByIndexPath:(NSIndexPath *)indexPath;

@end
