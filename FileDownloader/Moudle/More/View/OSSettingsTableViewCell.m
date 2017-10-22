//
//  OSSettingsTableViewCell.m
//  FileDownloader
//
//  Created by Swae on 2017/10/21.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSSettingsTableViewCell.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface OSSettingsTableViewCell ()

@property (strong, nonatomic) IBOutlet UIImageView *titleIcon;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *disclosureLabel;
@property (strong, nonatomic) IBOutlet UIImageView *disclosureIcon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelLeadingWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeadingWidth;
/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_Switch
@property (strong, nonatomic) IBOutlet UISwitch *disclosureSwitch;
@property (nonatomic) CGFloat titleLabelLeadingWidthForVisibleImage;

@property (nonatomic) OSSettingsMenuItemDisclosureType disclosureType;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *iconName;
/// Shown only if disclosureType is WMFSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText
@property (strong, nonatomic) NSString *disclosureText;
@property (strong, nonatomic) UIColor *iconColor;
@property (strong, nonatomic) UIColor *iconBackgroundColor;

@end

@implementation OSSettingsTableViewCell


- (void)setMenuItem:(OSSettingsMenuItem *)menuItem {
    _menuItem = menuItem;
    self.title = menuItem.title;
    self.iconName = menuItem.iconName;
    self.disclosureText = menuItem.disclosureText;
    self.disclosureType = menuItem.disclosureType;
    self.selectionStyle = (menuItem.disclosureType == OSSettingsMenuItemDisclosureTypeSwitch) ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
    
    if (menuItem.disclosureType != OSSettingsMenuItemDisclosureTypeSwitch && menuItem.disclosureType != OSSettingsMenuItemDisclosureTypeNormal) {
        self.accessibilityTraits = UIAccessibilityTraitButton;
    } else {
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
    }
    
    [self.disclosureSwitch removeTarget:menuItem.actionTarget action:menuItem.actionSelector forControlEvents:UIControlEventValueChanged];
    if (menuItem.disclosureType == OSSettingsMenuItemDisclosureTypeSwitch) {
        [self.disclosureSwitch setOn:menuItem.isSwitchOn animated:YES];
        [self.disclosureSwitch addTarget:menuItem.actionTarget action:menuItem.actionSelector forControlEvents:UIControlEventValueChanged];
    }
    
}

- (void)disclosureSwitchChanged:(UISwitch *)disclosureSwitch {
    [self updateStateForMenuItemType:self.disclosureType isSwitchOnValue:disclosureSwitch.isOn];
    if (self.disclosureSwitchChanged) {
        self.disclosureSwitchChanged(disclosureSwitch);
    }
}

#pragma mark - Switch tap handling

- (void)updateStateForMenuItemType:(OSSettingsMenuItemDisclosureType)type isSwitchOnValue:(BOOL)isOn {
    
}


- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setIconName:(NSString *)iconName {
    _iconName = iconName;
    self.titleIcon.image = [[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (_iconName) {
        self.titleIcon.hidden = NO;
        self.titleLabelLeadingWidth.constant = self.titleLabelLeadingWidthForVisibleImage;
    } else {
        self.titleIcon.hidden = YES;
        self.titleLabelLeadingWidth.constant = self.imageLeadingWidth.constant;
    }
}

- (void)setDisclosureText:(NSString *)disclosureText {
    _disclosureText = disclosureText;
    self.disclosureLabel.text = disclosureText;
}

- (UIImage *)backChevronImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [[UIImage xy_imageFlippedForRTLLayoutDirectionNamed:@"chevron-right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

- (UIImage *)externalLinkImage {
    static dispatch_once_t once;
    static UIImage *image;
    dispatch_once(&once, ^{
        image = [[UIImage xy_imageFlippedForRTLLayoutDirectionNamed:@"mini-external"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

- (void)setDisclosureType:(OSSettingsMenuItemDisclosureType)disclosureType {
    _disclosureType = disclosureType;
    switch (disclosureType) {
        case OSSettingsMenuItemDisclosureTypeNormal: {
            self.disclosureIcon.hidden = YES;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = nil;
            self.disclosureSwitch.hidden = YES;
            break;
        }
        case OSSettingsMenuItemDisclosureType_ExternalLink: {
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = [self externalLinkImage];
            self.disclosureSwitch.hidden = YES;
            break;
        }
        case OSSettingsMenuItemDisclosureTypeSwitch: {
            self.disclosureIcon.hidden = YES;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = nil;
            self.disclosureSwitch.hidden = NO;
            break;
        }
        case OSSettingsMenuItemDisclosureType_ViewController: {
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = YES;
            self.disclosureIcon.image = [self backChevronImage];
            self.disclosureSwitch.hidden = YES;
            break;
        }
        case OSSettingsMenuItemDisclosureType_ViewControllerWithDisclosureText: {
            self.disclosureIcon.hidden = NO;
            self.disclosureLabel.hidden = NO;
            self.disclosureIcon.image = [self backChevronImage];
            self.disclosureSwitch.hidden = YES;
            break;
        }
        default:
            break;
    }
}

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    self.titleIcon.tintColor = iconColor;
}

- (void)setIconBackgroundColor:(UIColor *)iconBackgroundColor {
    _iconBackgroundColor = iconBackgroundColor;
    self.titleIcon.backgroundColor = iconBackgroundColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // 在选中的动画中，重置titleicon的背景颜色
    self.iconColor = self.iconColor;
    self.iconBackgroundColor = self.iconBackgroundColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    // 重置titleicon的背景颜色
    self.iconColor = self.iconColor;
    self.iconBackgroundColor = self.iconBackgroundColor;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundView = [UIView new];
    self.selectedBackgroundView = [UIView new];
    self.titleLabelLeadingWidthForVisibleImage = self.titleLabelLeadingWidth.constant;
    [self applyTheme];
}

- (void)applyTheme {
    self.selectedBackgroundView.backgroundColor = UIColorFromRGB(0x222222);
    self.backgroundView.backgroundColor = UIColorFromRGB(0xFFFFFF);
    self.titleLabel.textColor = UIColorFromRGB(0x222222);
    self.disclosureLabel.textColor = UIColorFromRGB(0x72777D);
    self.iconBackgroundColor = UIColorFromRGB(0xE1DAD1);
    self.iconColor = UIColorFromRGB(0x646059);
    self.disclosureIcon.tintColor = UIColorFromRGB(0x72777D);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Touchs
////////////////////////////////////////////////////////////////////////

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *touchView = [super hitTest:point withEvent:event];
    if ([touchView isKindOfClass:[UIControl class]] && self.disclosureType != OSSettingsMenuItemDisclosureTypeNormal) {
        return touchView;
    }

    return touchView;
}


- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesEnded:touches withEvent:event];
    
    if (self.disclosureType == OSSettingsMenuItemDisclosureTypeNormal) {
        if (!self.menuItem.actionTarget || !self.menuItem.actionSelector) {
            return;
        }
        SEL selector = self.menuItem.actionSelector;
        NSString *selString = NSStringFromSelector(selector);
        NSInteger strCount = [selString length] - [[selString stringByReplacingOccurrencesOfString:@":" withString:@""] length];
        NSAssert(strCount <= 1, @"最多只能有一个参数");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[self.menuItem.actionTarget class] instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:self.menuItem.actionTarget];
        
        if (strCount > 0) {
            id target = self;
            [invocation setArgument:&target atIndex:2];
        }
        [invocation invoke];
    }
}

@end
