//
//  OSDrawerController.m
//  OSDrawerControllerSample
//
//  Created by Swae on 2017/11/15.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDrawerController.h"

static const CGFloat kCenterViewContainerCornerRadius = 5.0;
static const CGFloat kDefaultViewContainerWidth = 280.0;

@interface OSDrawerView : UIView

@property (nonatomic, strong) UIView *leftViewContainer;
@property (nonatomic, strong) UIView *rightViewContainer;
@property (nonatomic, strong) UIView *centerViewContainer;

@property (nonatomic, strong) UIImageView *backgroundImageView;

@property (nonatomic, assign) CGFloat leftViewContainerWidth;
@property (nonatomic, assign) CGFloat rightViewContainerWidth;

- (UIView *)viewContainerForDrawerSide:(OSDrawerSide)drawerSide;

- (void)willOpenDrawerViewController:(OSDrawerController *)viewController;
- (void)willCloseDrawerViewController:(OSDrawerController *)viewController;

@end

@interface OSDrawerController ()

/// 当前已打开的side
@property (nonatomic, assign) OSDrawerSide currentOpenedSide;
@property (nonatomic, strong) OSDrawerView *drawerView;
@property (nonatomic, strong) UITapGestureRecognizer *toggleDrawerTapGestureRecognizer;

@end

@implementation OSDrawerController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.currentOpenedSide = OSDrawerSideNone;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
}

- (void)setupViews {
    [self.view addSubview:self.drawerView];
    NSLayoutConstraint *top, *bottom, *left, *right;
    if (@available(iOS 11.0, *)) {
        top = [self.drawerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor];
        bottom = [self.drawerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
        left = [self.drawerView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor];
        right = [self.view.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor];
    }
    else if (@available(iOS 9.0, *)) {
        top = [self.drawerView.topAnchor constraintEqualToAnchor:self.view.topAnchor];
        bottom = [self.drawerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
        left = [self.drawerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
        right = [self.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];

    }
    else {
        top = [NSLayoutConstraint constraintWithItem:self.drawerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
        bottom = [NSLayoutConstraint constraintWithItem:self.drawerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
        left = [NSLayoutConstraint constraintWithItem:self.drawerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0];
        right = [NSLayoutConstraint constraintWithItem:self.drawerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0];
    }
    [NSLayoutConstraint activateConstraints:@[top, bottom, left, right]];
    
}


- (void)openWithSide:(OSDrawerSide)side animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    if(self.currentOpenedSide != side) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:side];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        // First close opened drawer and then open new drawer
        if(self.currentOpenedSide != OSDrawerSideNone) {
            [self closeWithSide:self.currentOpenedSide animated:animated completion:^(BOOL finished) {
                [self.animator presentationWithSide:side sideView:sideView centerView:centerView animated:animated completion:completion];
            }];
        } else {
            [self.animator presentationWithSide:side sideView:sideView centerView:centerView animated:animated completion:completion];
        }
        
        [self addDrawerGestures];
        [self.drawerView willOpenDrawerViewController:self];
    }
    
    self.currentOpenedSide = side;
}

- (void)closeWithSide:(OSDrawerSide)side animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    if(self.currentOpenedSide == side && self.currentOpenedSide != OSDrawerSideNone) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:side];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        [self.animator dismissWithSide:side sideView:sideView centerView:centerView animated:animated completion:completion];
        
        self.currentOpenedSide = OSDrawerSideNone;
        
        [self restoreGestures];
        
        [self.drawerView willOpenDrawerViewController:self];
    }
}

- (void)toggleWithSide:(OSDrawerSide)side animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    if(side != OSDrawerSideNone) {
        if (side == self.currentOpenedSide) {
            [self closeWithSide:side animated:animated completion:completion];
        } else {
            [self openWithSide:side animated:animated completion:completion];
        }
    }
}

#pragma mark *** Action ***

- (void)addDrawerGestures {
    self.centerViewController.view.userInteractionEnabled = NO;
    self.toggleDrawerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionCenterViewContainerTapped:)];
    [self.drawerView.centerViewContainer addGestureRecognizer:self.toggleDrawerTapGestureRecognizer];
}

- (void)restoreGestures {
    [self.drawerView.centerViewContainer removeGestureRecognizer:self.toggleDrawerTapGestureRecognizer];
    self.toggleDrawerTapGestureRecognizer = nil;
    self.centerViewController.view.userInteractionEnabled = YES;
}

- (void)actionCenterViewContainerTapped:(id)sender {
    [self closeWithSide:self.currentOpenedSide animated:YES completion:nil];
}


- (void)setLeftViewController:(UIViewController *)leftViewController {
    [self replaceViewController:self.leftViewController
             withViewController:leftViewController container:self.drawerView.leftViewContainer];
    
    _leftViewController = leftViewController;
}

- (void)setRightViewController:(UIViewController *)rightViewController {
    [self replaceViewController:self.rightViewController withViewController:rightViewController
                      container:self.drawerView.rightViewContainer];
    
    _rightViewController = rightViewController;
}

- (void)setCenterViewController:(UIViewController *)centerViewController {
    [self replaceViewController:self.centerViewController withViewController:centerViewController
                      container:self.drawerView.centerViewContainer];
    
    _centerViewController = centerViewController;
}

- (void)replaceViewController:(UIViewController *)sourceViewController withViewController:(UIViewController *)destinationViewController container:(UIView *)container {
    
    [sourceViewController willMoveToParentViewController:nil];
    [sourceViewController.view removeFromSuperview];
    [sourceViewController removeFromParentViewController];
    
    if (destinationViewController) {
        [self addChildViewController:destinationViewController];
        [container addSubview:destinationViewController.view];
        
        UIView *destinationView = destinationViewController.view;
        destinationView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(destinationView);
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[destinationView]|" options:0 metrics:nil views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[destinationView]|" options:0 metrics:nil views:views]];
        
        [destinationViewController didMoveToParentViewController:self];
    }
}


- (void)setLeftDrawerWidth:(CGFloat)leftDrawerWidth {
    self.drawerView.leftViewContainerWidth = leftDrawerWidth;
}

- (void)setRightDrawerWidth:(CGFloat)rightDrawerWidth {
    self.drawerView.rightViewContainerWidth = rightDrawerWidth;
}

- (CGFloat)leftDrawerRevealWidth {
    return self.drawerView.leftViewContainerWidth;
}

- (CGFloat)rightDrawerRevealWidth {
    return self.drawerView.rightViewContainerWidth;
}

#pragma mark *** Background Image ***

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    self.drawerView.backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
    return self.drawerView.backgroundImageView.image;
}

#pragma mark *** Others ***

- (UIViewController *)viewControllerForDrawerSide:(OSDrawerSide)drawerSide {
    UIViewController *sideViewController = nil;
    switch (drawerSide) {
        case OSDrawerSideLeft: sideViewController = self.leftViewController; break;
        case OSDrawerSideRight: sideViewController = self.rightViewController; break;
        case OSDrawerSideNone: sideViewController = nil; break;
    }
    return sideViewController;
}

#pragma mark *** Orientation ***

- (BOOL)shouldAutorotate {
    return [self.centerViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.centerViewController supportedInterfaceOrientations];;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self.centerViewController preferredInterfaceOrientationForPresentation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(self.currentOpenedSide != OSDrawerSideNone) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:self.currentOpenedSide];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        [self.animator willRotateOpenDrawerWithOpenSide:self.currentOpenedSide sideView:sideView centerView:centerView];
    }
    
    [self.centerViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(self.currentOpenedSide != OSDrawerSideNone) {
        UIView *sideView   = [self.drawerView viewContainerForDrawerSide:self.currentOpenedSide];
        UIView *centerView = self.drawerView.centerViewContainer;
        
        [self.animator didRotateOpenDrawerWithOpenSide:self.currentOpenedSide sideView:sideView centerView:centerView];
    }
    
    [self.centerViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - Status Bar

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.centerViewController;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.centerViewController;
}


- (OSDrawerView *)drawerView {
    if (!_drawerView) {
        _drawerView = [[OSDrawerView alloc] initWithFrame:CGRectZero];
        _drawerView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _drawerView;
}

@end

@interface OSDrawerView ()

@property (nonatomic, strong) NSLayoutConstraint *leftViewContainerWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *rightViewContainerWidthConstraint;

@end

@implementation OSDrawerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setup];
    }
    return self;
}

#pragma mark *** View Setup ***

- (void)setup {
    [self setupBackgroundImageView];
    [self setupCenterViewContainer];
    [self setupLeftViewContainer];
    [self setupRightViewContainer];
    
    [self bringSubviewToFront:self.centerViewContainer];
}

- (void)setupBackgroundImageView {
    _backgroundImageView = [[UIImageView alloc] init];
    
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.backgroundImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.backgroundImageView];
    
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:self.backgroundImageView attribute:NSLayoutAttributeLeading  relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.backgroundImageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.backgroundImageView attribute:NSLayoutAttributeTop      relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.backgroundImageView attribute:NSLayoutAttributeBottom   relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
                             ];
    
    [self addConstraints:constraints];
}

- (void)setupLeftViewContainer {
    _leftViewContainer = [[UIView alloc] init];
    
    [self.leftViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.leftViewContainer];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.leftViewContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kDefaultViewContainerWidth];
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:self.leftViewContainer attribute:NSLayoutAttributeHeight   relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.leftViewContainer attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.leftViewContainer attribute:NSLayoutAttributeTop      relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
                             widthConstraint
                             ];
    
    [self addConstraints:constraints];
    
    self.leftViewContainerWidthConstraint = widthConstraint;
}

- (void)setupRightViewContainer {
    _rightViewContainer = [[UIView alloc] init];
    
    [self.rightViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.rightViewContainer];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.rightViewContainer attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kDefaultViewContainerWidth];
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:self.rightViewContainer attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual  toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.rightViewContainer attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.rightViewContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual     toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
                             widthConstraint
                             ];
    
    [self addConstraints:constraints];
    
    self.rightViewContainerWidthConstraint = widthConstraint;
}

- (void)setupCenterViewContainer {
    _centerViewContainer = [[UIView alloc] init];
    
    [self.centerViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:self.centerViewContainer];
    
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:self.centerViewContainer attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.centerViewContainer attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.centerViewContainer attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0],
                             [NSLayoutConstraint constraintWithItem:self.centerViewContainer attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0],
                             ];
    
    [self addConstraints:constraints];
}

#pragma mark - Reveal Widths

- (void)setLeftViewContainerWidth:(CGFloat)leftViewContainerWidth {
    self.leftViewContainerWidthConstraint.constant = leftViewContainerWidth;
}

- (void)setRightViewContainerWidth:(CGFloat)rightViewContainerWidth {
    self.rightViewContainerWidthConstraint.constant = rightViewContainerWidth;
}

- (CGFloat)leftViewContainerWidth {
    return self.leftViewContainerWidthConstraint.constant;
}

- (CGFloat)rightViewContainerWidth {
    return self.rightViewContainerWidthConstraint.constant;
}

#pragma mark - Helpers

- (UIView *)viewContainerForDrawerSide:(OSDrawerSide)drawerSide {
    UIView *viewContainer = nil;
    switch (drawerSide) {
        case OSDrawerSideLeft: viewContainer = self.leftViewContainer; break;
        case OSDrawerSideRight: viewContainer = self.rightViewContainer; break;
        case OSDrawerSideNone: viewContainer = nil; break;
    }
    return viewContainer;
}

#pragma mark - Open/Close Events

- (void)willOpenDrawerViewController:(OSDrawerController *)viewController {
//    [self applyBorderRadiusToCenterViewController];
//    [self applyShadowToCenterViewContainer];
}

- (void)willCloseDrawerViewController:(OSDrawerController *)viewController {
//    [self removeBorderRadiusFromCenterViewController];
//    [self removeShadowFromCenterViewContainer];
}

#pragma mark - View Related

//// Notice, border is applied to centerViewController.view whereas shadow is applied to
//// drawerView.centerViewContainer. This is because cornerRadius requires masksToBounds = YES
//// but for shadows to render outside the view, masksToBounds must be NO. So we apply them on
//// different views.
//- (void)applyBorderRadiusToCenterViewController {
//    // FIXME: Safe? Maybe move this into a property
//    UIView *containerCenterView = [self.centerViewContainer.subviews firstObject];
//
//    CALayer *centerLayer = containerCenterView.layer;
//    centerLayer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
//    centerLayer.borderWidth = 1.0;
//    centerLayer.cornerRadius = kCenterViewContainerCornerRadius;
//    centerLayer.masksToBounds = YES;
//}
//
//- (void)removeBorderRadiusFromCenterViewController {
//    // FIXME: Safe? Maybe move this into a property
//    UIView *containerCenterView = [self.centerViewContainer.subviews firstObject];
//
//    CALayer *centerLayer = containerCenterView.layer;
//    centerLayer.borderColor = [UIColor clearColor].CGColor;
//    centerLayer.borderWidth = 0.0;
//    centerLayer.cornerRadius = 0.0;
//    centerLayer.masksToBounds = NO;
//}

- (void)applyShadowToCenterViewContainer {
    CALayer *layer = self.centerViewContainer.layer;
    layer.shadowRadius  = 20.0;
    layer.shadowColor   = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.4;
    layer.shadowOffset  = CGSizeMake(0.0, 0.0);
    layer.masksToBounds = NO;
    
    [self updateShadowPath];
}

- (void)removeShadowFromCenterViewContainer {
    CALayer *layer = self.centerViewContainer.layer;
    layer.shadowRadius  = 0.0;
    layer.shadowOpacity = 0.0;
}

- (void)updateShadowPath {
    CALayer *layer = self.centerViewContainer.layer;
    
    CGFloat increase = layer.shadowRadius;
    CGRect centerViewContainerRect = self.centerViewContainer.bounds;
    centerViewContainerRect.origin.x -= increase;
    centerViewContainerRect.origin.y -= increase;
    centerViewContainerRect.size.width  += 2.0 * increase;
    centerViewContainerRect.size.height += 2.0 * increase;
    
    layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:centerViewContainerRect cornerRadius:kCenterViewContainerCornerRadius] CGPath];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateShadowPath];
}


@end

