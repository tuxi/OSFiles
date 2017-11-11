//
//  MainNavigationController.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/12.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "MainNavigationController.h"

@interface MainNavigationController ()

@end

@implementation MainNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)getTopViewController {
    UIViewController *vc = [self.viewControllers lastObject];
    return vc;
}

- (BOOL)shouldAutorotate{
    UIViewController *vc = [self getTopViewController];
    return vc.shouldAutorotate;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    UIViewController *vc = [self getTopViewController];
    return [vc preferredInterfaceOrientationForPresentation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    UIViewController *vc = [self getTopViewController];
    return [vc supportedInterfaceOrientations];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    if (self.childViewControllers.count == 1) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    [super pushViewController:viewController animated:animated];
}


@end
