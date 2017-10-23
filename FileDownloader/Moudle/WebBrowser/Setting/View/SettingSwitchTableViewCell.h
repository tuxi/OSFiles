//
//  SettingSwitchTableViewCell.h
//  WebBrowser
//
//  Created by Null on 2017/2/14.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ValueChangedBlock)(UISwitch *);

@interface SettingSwitchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *leftLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;
@property (copy, nonatomic) ValueChangedBlock valueChangedBlock;

@end
