//
//  OSFileBottomHUD.h
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSFileBottomHUD, OSFileBottomHUDItem;

@protocol OSFileBottomHUDDelegate <NSObject>

@optional
- (void)fileBottomHUD:(OSFileBottomHUD *)hud didClickItem:(OSFileBottomHUDItem *)item;

@end

@interface OSFileBottomHUDItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign, readonly) NSInteger buttonIdx;
@property (nonatomic, weak, readonly) UIButton *button;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image;
- (NSString *)titleForState:(UIControlState)state;
- (NSString *)imageForState:(UIControlState)state;
- (void)setImage:(UIImage *)image state:(UIControlState)state;
- (void)setTitle:(NSString *)title state:(UIControlState)state;

@end

@interface OSFileBottomHUD : UIView

@property (nonatomic, weak) id<OSFileBottomHUDDelegate> delegate;

- (instancetype)initWithItems:(NSArray<OSFileBottomHUDItem *> *)items toView:(UIView *)view;
- (void)hideHudCompletion:(void (^)(OSFileBottomHUD *hud))completion;
- (void)showHUDWithFrame:(CGRect)frame completion:(void (^)(OSFileBottomHUD *hud))completion;
- (void)setItemTitle:(NSString *)title index:(NSInteger)index state:(UIControlState)state;
- (void)setItemImage:(UIImage *)image index:(NSInteger)index state:(UIControlState)state;

@end

