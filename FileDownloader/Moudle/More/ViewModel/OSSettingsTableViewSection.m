//
//  OSSettingsTableViewSection.m
//  FileDownloader
//
//  Created by Swae on 2017/10/22.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSSettingsTableViewSection.h"

@implementation OSSettingsTableViewSection

- (instancetype)initWithItem:(NSArray *)items headerTitle:(NSString *)headerTitle footerText:(NSString *)footerText {
    if (self = [super init]) {
        self.items = items.copy;
        self.headerTitle = headerTitle;
        self.footerText = footerText;
    }
    return self;
}

@end
