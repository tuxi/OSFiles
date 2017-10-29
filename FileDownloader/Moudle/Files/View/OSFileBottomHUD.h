//
//  OSFileBottomHUD.h
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSFileBottomHUD : UIView

- (instancetype)initWithView:(UIView *)view;
- (void)hideHudCompletion:(void (^)(void))completion;
- (void)showHUDWithFrame:(CGRect)frame completion:(void (^)(void))completion;

@end
