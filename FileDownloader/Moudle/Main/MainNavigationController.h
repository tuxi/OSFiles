//
//  MainNavigationController.h
//  MVVMDemo
//
//  Created by alpface on 17/2/12.
//  Copyright © 2017年 alpface. All rights reserved.
//

@import UIKit;

@interface MainNavigationController : UINavigationController <ICSDrawerControllerChild, ICSDrawerControllerPresenting>

@property (nonatomic, weak) ICSDrawerController *drawer;

@end
