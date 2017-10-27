//
//  OSSettingsMenuItem.m
//  OSFileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSSettingsMenuItem.h"
#import "SmileAuthenticator.h"

@interface OSSettingsMenuItem ()

@property (nonatomic, copy, readwrite) NSString *title;

@property (nonatomic, copy, readwrite) NSString *iconName;

@property (nonatomic, copy, readwrite) UIColor *iconColor;

@property (nonatomic, assign, readwrite) OSSettingsMenuItemDisclosureType disclosureType;

@property (nonatomic, copy, readwrite) NSString *disclosureText;

@end

@implementation OSSettingsMenuItem

+ (instancetype)switchCellForSel:(SEL)sel
                          target:(id)target
                           title:(NSString *)title
                        iconName:(NSString *)iconName
                              on:(BOOL)isOn {
    OSSettingsMenuItem *item = [[self alloc] initWithTitle:title
                                                  iconName:iconName
                                                 iconColor:UIColorFromRGB(0xFF1B33)
                                            disclosureType:OSSettingsMenuItemDisclosureTypeSwitch
                                            disclosureText:nil
                                                isSwitchOn:isOn];
    item.actionSelector = sel;
    item.actionTarget = target;
    
    return item;
    
}

+ (instancetype)normalCellForSel:(SEL)sel
                          target:(id)target
                           title:(NSString *)title
                        iconName:(NSString *)iconName  {
    OSSettingsMenuItem *item = [[self alloc] initWithTitle:title
                                                  iconName:iconName
                                                 iconColor:UIColorFromRGB(0xFF1B33)
                                            disclosureType:OSSettingsMenuItemDisclosureTypeNormal
                                            disclosureText:nil
                                                isSwitchOn:NO];
    item.actionSelector = sel;
    item.actionTarget = target;
    
    return item;
}

+ (instancetype)cellForSel:(SEL)sel
                          target:(id)target
                           title:(NSString *)title
                        iconName:(NSString *)iconName
                  disclosureType:(OSSettingsMenuItemDisclosureType)disclosureType {
    OSSettingsMenuItem *item = [[self alloc] initWithTitle:title
                                                  iconName:iconName
                                                 iconColor:UIColorFromRGB(0xFF1B33)
                                            disclosureType:disclosureType
                                            disclosureText:nil
                                                isSwitchOn:NO];
    item.actionSelector = sel;
    item.actionTarget = target;
    
    return item;
}

- (instancetype)initWithTitle:(NSString *)title
                    iconName:(NSString *)iconName
                   iconColor:(UIColor *)iconColor
              disclosureType:(OSSettingsMenuItemDisclosureType)disclosureType
              disclosureText:(NSString *)disclosureText
                  isSwitchOn:(BOOL)isSwitchOn {
    self = [super init];
    if (self) {
        self.disclosureType = disclosureType;
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
