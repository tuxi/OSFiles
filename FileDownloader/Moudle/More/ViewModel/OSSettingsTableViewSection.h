//
//  OSSettingsTableViewSection.h
//  OSFileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSSettingsMenuItem.h"

@interface OSSettingsTableViewSection : NSObject

@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *footerText;
@property (nonatomic, strong) NSArray<OSSettingsMenuItem *> *items;

- (instancetype)initWithItem:(NSArray *)items headerTitle:(NSString *)headerTitle footerText:(NSString *)footerText;

@end
