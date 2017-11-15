//
//  OSDrawerController.h
//  OSDrawerControllerSample
//
//  Created by Swae on 2017/11/15.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSDrawerAnimation.h"

@interface OSDrawerController : UIViewController

@property (nonatomic, strong) UIViewController *leftViewController;
@property (nonatomic, strong) UIViewController *rightViewController;
@property (nonatomic, strong) UIViewController *centerViewController;

@property (nonatomic, strong) id<OSDrawerAnimation> animator;

@property (nonatomic, strong) UIImage *backgroundImage;

@property (nonatomic, assign) CGFloat leftDrawerWidth;
@property (nonatomic, assign) CGFloat rightDrawerWidth;

- (void)openWithSide:(OSDrawerSide)side animated:(BOOL)animated completion:(void (^)(BOOL isFinished))completion;
- (void)closeWithSide:(OSDrawerSide)side animated:(BOOL)animated completion:(void (^)(BOOL isFinished))completion;
- (void)toggleWithSide:(OSDrawerSide)side animated:(BOOL)animated completion:(void (^)(BOOL isFinished))completion;

@end



