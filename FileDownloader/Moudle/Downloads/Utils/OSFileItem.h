//
//  FileItem.h
//  OSFileDownloader
//
//  Created by Swae on 2017/10/19.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFile.h"
#import "OSFileDownloadConst.h"
#import "OSFileDownloadProgress.h"

@interface OSFileItem : OSFile <NSCoding>

@property (nonatomic, copy) NSString *packageId;
@property (nonatomic, assign) OSFileDownloadStatus status;
@property (nonatomic, copy) NSString *urlPath;
@property (nonatomic, copy) NSString *MIMEType;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *localFolderPath;
@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, assign) NSInteger lastHttpStatusCode;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, strong) NSArray *errorMessagesStack;
@property (nonatomic, strong) OSFileDownloadProgress *progressObj;

@end
