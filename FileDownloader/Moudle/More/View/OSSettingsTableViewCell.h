//
//  OSSettingsTableViewCell.h
//  FileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSSettingsMenuItem.h"

@interface OSSettingsTableViewCell : UITableViewCell

@property (nonatomic, strong) OSSettingsMenuItem *menuItem;

@property (nonatomic, copy) void (^ disclosureSwitchChanged)(UISwitch *sw);

@end
