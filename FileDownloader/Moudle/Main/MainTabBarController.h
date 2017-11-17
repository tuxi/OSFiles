//
//  MainTabBarController.h
//  MVVMDemo
//
//  Created by mofeini on 17/2/12.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainTabBarController : UITabBarController <ICSDrawerControllerChild, ICSDrawerControllerPresenting>

@property (nonatomic, weak) ICSDrawerController *drawer;

@end
