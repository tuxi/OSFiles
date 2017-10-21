//
//  OSSettingsMenuItem.h
//  FileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OSSettingsMenuItemType) {
    OSSettingsMenuItemTypePassword
};

typedef NS_ENUM(NSUInteger, OSSettingsMenuItemDisclosureType) {
    OSSettingsMenuItemDisclosureType_None,
    OSSettingsMenuItemDisclosureType_ViewController,
    OSSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText,
    OSSettingsMenuItemDisclosureType_ExternalLink,
    OSSettingsMenuItemDisclosureType_Switch,
    OSSettingsMenuItemDisclosureType_Password
};

@interface OSSettingsMenuItem : NSObject

@property (nonatomic, assign, readonly) OSSettingsMenuItemType type;

@property (nonatomic, copy, readonly) NSString *title;

@property (nonatomic, copy, readonly) NSString *iconName;

@property (nonatomic, copy, readonly) UIColor *iconColor;

@property (nonatomic, assign, readonly) OSSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readonly) NSString *disclosureText;

@property (nonatomic, assign, readwrite) BOOL isSwitchOn;

+ (instancetype)itemForType:(OSSettingsMenuItemType)type;

- (instancetype)initWithType:(OSSettingsMenuItemType)type
                       title:(NSString *)title
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
              disclosureType:(OSSettingsMenuItemDisclosureType)disclosureType
              disclosureText:(NSString *)disclosureText
                  isSwitchOn:(BOOL)isSwitchOn;

@end
