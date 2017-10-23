//
//  FileItem.h
//  FileDownloader
//
//  Created by Swae on 2017/10/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFile.h"
#import "FileDownloadConst.h"
#import "FileDownloadProgress.h"

@interface FileItem : OSFile <NSCoding>

@property (nonatomic, copy) NSString *packageId;
@property (nonatomic, assign) FileDownloadStatus status;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, copy) NSString *MIMEType;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *localFolderPath;
@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, assign) NSInteger lastHttpStatusCode;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, strong) NSArray *errorMessagesStack;
@property (nonatomic, strong) FileDownloadProgress *progressObj;

@end
