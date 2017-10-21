//
//  DownloadsTableViewModel.h
//  FileDownloader
//
//  Created by Ossey on 2017/6/12.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "BaseTableViewModel.h"
#import "FileDownloadCell.h"

@interface DownloadsTableViewModel : BaseTableViewModel

- (FileDownloadCell *)getDownloadCellByIndexPath:(NSIndexPath *)indexPath;

@end
