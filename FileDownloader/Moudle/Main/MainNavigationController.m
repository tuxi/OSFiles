//
//  MainNavigationController.m
//  MVVMDemo
//
//  Created by mofeini on 17/2/12.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import "MainNavigationController.h"
#import <Aspects.h>

@interface MainNavigationController () <UINavigationControllerDelegate> {
    BOOL _pushing;
    id<AspectToken> _aspect;
}

@end

@implementation MainNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.delegate = self; //默认代理设置Self
    }
    return self;
}

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

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (self.childViewControllers.count == 1) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    
    // 防止子控制器重复push
    //这个地方有个问题，initWithRootViewController会触发pushViewController
    if (self.viewControllers.count == 0) {
        [super pushViewController:viewController animated:animated];
        return;
    }
    
    if (_pushing == YES) {
        NSLog(@"拦截到重复push: %@",viewController);
        return;
    }
    else {
        NSLog(@"push %@", viewController);
        _pushing = YES;
    }

    [super pushViewController:viewController animated:animated];
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate {
    [super setDelegate:delegate];
    
    // 移除_aspect
    if (_aspect) {
        [_aspect remove];
    }
    
    if (delegate && ![self isEqual:delegate]) {
        // 不是Self
        if ([delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
            //当delegate已经实现 navigationController:didShowViewController:animated: 的时候，
            //Hook 该方法
            //当然也可以使用 swizzleMethod ，Aspect的API更友好些
            __weak __typeof(&*self) weakSelf = self;
            _aspect = [((NSObject *)delegate) aspect_hookSelector:@selector(navigationController:didShowViewController:animated:) withOptions:AspectPositionAfter usingBlock:^(id instance, NSArray *args) {
                __strong typeof(&*weakSelf) self = weakSelf;
                [self navigationController:args[0] didShowViewController:args[1] animated:[args[2] boolValue]];
                
            } error:nil];
        }
        else {
            //为delegate动态添加 navigationController:didShowViewController:animated:
            //不知道有没有这方面的库可以用，只能自己写
            Class class = [delegate class];
            
            swizzleMethod(class, @selector(navigationController:didShowViewController:animated:), @selector(navigationController:didShowViewController:animated:));
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UINavigationControllerDelegate
////////////////////////////////////////////////////////////////////////
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 完成PUSH
    _pushing = NO;
}

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark - ICSDrawerControllerPresenting

- (void)drawerControllerWillOpen:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = NO;
}

- (void)drawerControllerDidOpen:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = YES;
}

- (void)drawerControllerWillClose:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = NO;
}

- (void)drawerControllerDidClose:(ICSDrawerController *)drawerController {
    self.view.userInteractionEnabled = YES;
}



@end
