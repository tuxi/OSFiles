//
//  OSFileCollectionViewCell.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileAttributeItem;

@interface OSFileCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) OSFileAttributeItem *fileModel;

@end
