//
//  OSSettingsMenuItem.m
//  FileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSSettingsMenuItem.h"

@interface OSSettingsMenuItem ()

@property (nonatomic, assign, readwrite) OSSettingsMenuItemType type;

@property (nonatomic, copy, readwrite) NSString *title;

@property (nonatomic, copy, readwrite) NSString *iconName;

@property (nonatomic, copy, readwrite) UIColor *iconColor;

@property (nonatomic, assign, readwrite) OSSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readwrite) NSString *disclosureText;

@end

@implementation OSSettingsMenuItem


+ (instancetype)itemForType:(OSSettingsMenuItemType)type {
    OSSettingsMenuItem *item = nil;
    switch (type) {
        case OSSettingsMenuItemTypePassword: {
            BOOL isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@(OSSettingsMenuItemDisclosureType_Password).stringValue];
           item = [[self alloc] initWithType:type
                                       title:@"设置密码"
                                    iconName:@"settings-zero"
                                   iconColor:UIColorFromRGB(0xFF1B33)
                              disclosureType:OSSettingsMenuItemDisclosureType_Password
                              disclosureText:nil
                                  isSwitchOn:isSwitchOn];
            break;
        }
        default:
            break;
    }
    return item;
}

- (instancetype)initWithType:(OSSettingsMenuItemType)type
                       title:(NSString *)title
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
              disclosureType:(OSSettingsMenuItemDisclosureType)disclosureType
              disclosureText:(NSString *)disclosureText
                  isSwitchOn:(BOOL)isSwitchOn {
    self = [super init];
    if (self) {
        self.type = type;
        self.title = title;
        self.iconName = iconName;
        self.iconColor = iconColor;
        self.disclosureType = disclosureType;
        self.disclosureText = disclosureText;
        self.isSwitchOn = isSwitchOn;
    }
    return self;
}


@end
