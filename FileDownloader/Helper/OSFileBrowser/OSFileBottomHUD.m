//
//  OSFileBottomHUD.m
//  FileBrowser
//
//  Created by xiaoyuan on 05/08/2014.
//  Copyright © 2014 xiaoyuan. All rights reserved.
//

#import "OSFileBottomHUD.h"

@interface OSFileBottomHUDViewController : UIViewController

@end

@implementation OSFileBottomHUDViewController

- (BOOL)shouldAutorotate{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}



- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    UIWindow *window = self.view.window;
    [window bringSubviewToFront:window.rootViewController.view];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    UIWindow *window = self.view.window;
    [window bringSubviewToFront:window.rootViewController.view];
}



@end

@interface OSFileBottomHUDButton : UIButton

@property (nonatomic) CGFloat imageTitleSpace;

@end


@interface OSFileBottomHUDItem ()

@property (nonatomic, assign) NSInteger buttonIdx;
@property (nonatomic, strong) NSMutableDictionary *buttonTitleDictionary;
@property (nonatomic, strong) NSMutableDictionary *buttonImageDictionary;
@property (nonatomic, weak) UIButton *button;

@end

@interface OSFileBottomHUD ()

@property (nonatomic, strong) UIWindow *xy_parentWindow;
@property (nonatomic, assign) CGRect hideRect;
@property (nonatomic, weak) UIView *toView;
@property (nonatomic, strong) NSArray<OSFileBottomHUDItem *> *items;
@property (nonatomic, strong) NSArray<UIButton *> *buttons;

@end

@implementation OSFileBottomHUD

- (instancetype)initWithItems:(NSArray<OSFileBottomHUDItem *> *)items toView:(UIView *)view {
    if (self = [super initWithFrame:CGRectZero]) {
        NSAssert(view, @"view do not nil");
        self.toView = view;
        self.items = items;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, self.toView.frame.size.height, self.toView.frame.size.width, self.frame.size.height)];
    _xy_parentWindow = window;
    OSFileBottomHUDViewController *vc = [[OSFileBottomHUDViewController alloc] init];
    window.rootViewController = vc;
    [vc.view addSubview:self];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [vc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:kNilOptions metrics:nil views:@{@"view": self}]];
    [vc.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:kNilOptions metrics:nil views:@{@"view": self}]];
    self.backgroundColor = [UIColor whiteColor];
    vc.view.backgroundColor = [UIColor whiteColor];
    window.layer.masksToBounds = YES;
    window.hidden = NO;
    
    [self setupViews];
}

- (void)setupViews {
    NSMutableArray *btnlist =@[].mutableCopy;
    NSInteger i = 0;
    for (OSFileBottomHUDItem *item in self.items) {
        OSFileBottomHUDButton *btn = [OSFileBottomHUDButton buttonWithType:UIButtonTypeCustom];
        item.button = btn;
        btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        btn.contentMode = UIViewContentModeScaleAspectFit;
        [btn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [btn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [btn setTitle:item.title forState:UIControlStateNormal];
        [btn setImage:item.image forState:UIControlStateNormal];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        btn.hidden = NO;
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        item.buttonIdx = i;
        btn.tag = i;
        [self addSubview:btn];
        [btnlist addObject:btn];
        i++;
    }
    self.buttons = btnlist;
    
    [self updateSubViewsConstraints];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)updateSubViewsConstraints {
    
    NSMutableDictionary *subviewDict = @{}.mutableCopy;
    NSMutableString *verticalFormat = [NSMutableString new];
    
    NSInteger i = 0;
    UIButton *previousBtn = nil;
    for (UIButton *btn in self.buttons) {
        NSString *btnKey = [NSString stringWithFormat:@"btn%ld", i];
        subviewDict[btnKey] = btn;
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[%@]|", btnKey] options:kNilOptions metrics:nil views:subviewDict]];
        if (previousBtn) {
            [self addConstraint:[NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:previousBtn attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
        }
        [verticalFormat appendFormat:@"-(%.f@1000)-[%@]", 0.0, btnKey];
        if (i == self.buttons.count - 1) {
            // 最后一个控件把距离父控件底部的约束值也加上
            [verticalFormat appendFormat:@"-(%.f@1000)-", 0.0];
        }
        previousBtn = btn;
        i++;
    }
    
    if (verticalFormat.length) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"|%@|", verticalFormat] options:kNilOptions metrics:nil views:subviewDict]];
    }
    
    [UIView performWithoutAnimation:^{
        [self layoutIfNeeded];
    }];
}

- (void)showHUDWithFrame:(CGRect)frame completion:(void (^)(OSFileBottomHUD *))completion {
    [UIView animateWithDuration:0.2 animations:^{
        self.xy_parentWindow.hidden = NO;
        CGRect hudFrame = self.xy_parentWindow.frame;
        if (CGRectIsEmpty(frame)) {
            hudFrame = self.frame;
        }
        else {
            hudFrame = frame;
        }
        
        self.xy_parentWindow.frame = hudFrame;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(self);
        }
    }];
    
}

- (void)hideHudCompletion:(void (^)(OSFileBottomHUD *hud))completion {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect frame = self.xy_parentWindow.frame;
        frame.origin.y = self.toView.frame.size.height;
        self.xy_parentWindow.frame =  frame;
    } completion:^(BOOL finished) {
        self.xy_parentWindow.hidden = YES;
        if (completion) {
            completion(self);
        }
    }];
    
}

- (void)btnClick:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileBottomHUD:didClickItem:)]) {
        OSFileBottomHUDItem *item = [self.items objectAtIndex:btn.tag];
        [self.delegate fileBottomHUD:self didClickItem:item];
    }
}

- (void)setItemTitle:(NSString *)title index:(NSInteger)index state:(UIControlState)state {
    NSAssert(index < self.items.count, @"index 必须在items的范围内");
    [self.items[index] setTitle:title state:state];
}
- (void)setItemImage:(UIImage *)image index:(NSInteger)index state:(UIControlState)state {
    NSAssert(index < self.items.count, @"index 必须在items的范围内");
    [self.items[index] setImage:image state:state];
}

@end


@implementation OSFileBottomHUDItem

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image {
    if (self = [super init]) {
        self.title = title;
        self.image = image;
        
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    if (title) {
        self.buttonTitleDictionary[@(UIControlStateNormal)] = title;
    }
    else {
        [self.buttonTitleDictionary removeObjectForKey:@(UIControlStateNormal)];
    }
    [self.button setTitle:title forState:UIControlStateNormal];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    if (image) {
        self.buttonImageDictionary[@(UIControlStateNormal)] = image;
    }
    else {
        [self.buttonImageDictionary removeObjectForKey:@(UIControlStateNormal)];
    }
    [self.button setImage:image forState:UIControlStateNormal];
}

- (void)setImage:(UIImage *)image state:(UIControlState)state {
    _image = image;
    self.buttonImageDictionary[@(state)] = image;
    [self.button setImage:image forState:state];
}

- (void)setTitle:(NSString *)title state:(UIControlState)state {
    _title = title;
    self.buttonTitleDictionary[@(state)] = title;
    [self.button setTitle:title forState:state];
}

- (NSMutableDictionary *)buttonTitleDictionary {
    if (!_buttonTitleDictionary) {
        _buttonTitleDictionary = @{}.mutableCopy;
    }
    return _buttonTitleDictionary;
}

- (NSMutableDictionary *)buttonImageDictionary {
    if (!_buttonImageDictionary) {
        _buttonImageDictionary = @{}.mutableCopy;
    }
    return _buttonImageDictionary;
}

- (NSString *)titleForState:(UIControlState)state {
    return self.buttonTitleDictionary[@(state)];
}

- (NSString *)imageForState:(UIControlState)state {
    return self.buttonImageDictionary[@(state)];
}

@end


@implementation OSFileBottomHUDButton {
    CGSize _titleLabelSize;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}


// 图片太大，文本显示不出来，控制button中image的尺寸
// imageRectForContentRect:和titleRectForContentRect:不能互相调用imageView和titleLael,不然会死循环
- (CGRect)imageRectForContentRect:(CGRect)bounds {
    if (CGSizeEqualToSize(_titleLabelSize, CGSizeZero)) {
        return CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
    }
    return CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height-_titleLabelSize.height);
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    if (self.imageView.image) {
        return CGRectMake(0.0, self.imageView.bounds.size.height, self.bounds.size.width, self.bounds.size.height-self.imageView.bounds.size.height);
    }
    return CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
    
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    [super setTitle:title forState:state];
    _titleLabelSize = [self string:title sizeWithMaxSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) font:self.titleLabel.font];
}

- (CGSize)string:(NSString *)string sizeWithMaxSize:(CGSize)maxSize font:(UIFont*)font {
    
    CGSize textSize = CGSizeZero;
    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin |
        NSStringDrawingUsesFontLeading;
        
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineBreakMode:NSLineBreakByCharWrapping];
        
        NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : style };
        
        CGRect rect = [string boundingRectWithSize:maxSize
                                           options:opts
                                        attributes:attributes
                                           context:nil];
        textSize = rect.size;
    }
    else{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        textSize = [string sizeWithFont:font constrainedToSize:maxSize lineBreakMode:NSLineBreakByCharWrapping];
#pragma clang diagnostic pop
    }
    
    return textSize;
}



@end


