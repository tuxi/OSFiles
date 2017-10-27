//
//  OSSettingsMenuItem.h
//  OSFileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OSSettingsMenuItemDisclosureType) {
    OSSettingsMenuItemDisclosureTypeNormal,
    OSSettingsMenuItemDisclosureTypeViewController,
    OSSettingsMenuItemDisclosureTypeViewControllerWithDisclosureText,
    OSSettingsMenuItemDisclosureTypeExternalLink,
    OSSettingsMenuItemDisclosureTypeSwitch,
};

@interface OSSettingsMenuItem : NSObject

@property (nonatomic, assign, readonly) OSSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readonly) NSString *title;

@property (nonatomic, copy, readonly) NSString *iconName;

@property (nonatomic, copy, readonly) UIColor *iconColor;

@property (nonatomic, copy, readonly) NSString *disclosureText;

@property (nonatomic, assign, readwrite) BOOL isSwitchOn;

@property (nonatomic, assign) SEL actionSelector;
@property (nonatomic, weak) id actionTarget;

+ (instancetype)switchCellForSel:(SEL)sel
                          target:(id)target
                           title:(NSString *)title
                        iconName:(NSString *)iconName
                              on:(BOOL)isOn;


+ (instancetype)normalCellForSel:(SEL)sel
                          target:(id)target
                           title:(NSString *)title
                        iconName:(NSString *)iconName;

- (instancetype)initWithTitle:(NSString *)title
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
              disclosureType:(OSSettingsMenuItemDisclosureType)disclosureType
              disclosureText:(NSString *)disclosureText
                  isSwitchOn:(BOOL)isSwitchOn;

+ (instancetype)cellForSel:(SEL)sel
                    target:(id)target
                     title:(NSString *)title
                  iconName:(NSString *)iconName
            disclosureType:(OSSettingsMenuItemDisclosureType)disclosureType;

@end
