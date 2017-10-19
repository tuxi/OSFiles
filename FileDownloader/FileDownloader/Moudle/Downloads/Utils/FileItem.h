//
//  FileItem.h
//  FileDownloader
//
//  Created by Swae on 2017/10/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadConst.h"

@interface FileItem : NSObject <NSCoding>

@property (nonatomic, copy) NSString *packageId;
@property (nonatomic, assign) FileDownloadStatus status;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, copy) NSString *MIMEType;

@end
