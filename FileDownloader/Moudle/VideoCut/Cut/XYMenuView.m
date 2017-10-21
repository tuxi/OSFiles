//
//  XYMenuView.m
//  XYMenuView
//
//  Created by mofeini on 16/11/15.
//  Copyright © 2016年 com.test.demo. All rights reserved.
//

#import "XYMenuView.h"
#import "UIButton+ClickBlock.h"

@interface XYMenuView ()
@property (nonatomic, weak) UIView *maskView;
@property (nonatomic, weak) UIView *contentView;
/** 快速导出 **/
@property (nonatomic, weak) UIButton *fastExportBtn;
/** 高清导出 **/
@property (nonatomic, weak) UIButton *hdExportBtn;
/** 超清导出 **/
@property (nonatomic, weak) UIButton *superclearBtn;
/** 取消 **/
@property (nonatomic, weak) UIButton *cancelBtn;

@property (nonatomic, weak) NSLayoutConstraint *selfTopConstr;
@end

@implementation XYMenuView


+ (instancetype)menuViewToSuperView:(UIView *)superView {
    
    XYMenuView *menuView = [[self alloc] init];
    if (superView) {
        [superView addSubview:menuView];
        
        // 默认让创建出来的menView在父控件的最底部
        menuView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [superView addConstraint:[NSLayoutConstraint constraintWithItem:menuView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
        [superView addConstraint:[NSLayoutConstraint constraintWithItem:menuView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
        [superView addConstraint:[NSLayoutConstraint constraintWithItem:menuView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
        NSLayoutConstraint *menuViewTopConstr = [NSLayoutConstraint constraintWithItem:menuView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superView attribute:NSLayoutAttributeTop multiplier:1.0 constant:superView.frame.size.height];
        [superView addConstraint:menuViewTopConstr];
        menuView.selfTopConstr = menuViewTopConstr;
        
        [superView layoutIfNeeded];
        menuView.hidden = YES;
    }
    return menuView;
}

// 隐藏menuView，并在隐藏动画执行完毕后回调block
- (void)dismissMenuView:(void(^)())block {
    
    UIView *superView = self.superview;
    
    if (superView) {
        self.maskView.hidden = YES;
        
        // 更新menuView的约束到父控件view的最底部，并隐藏
//        _selfTopConstr.priority = 800; // 约束优先级
        _selfTopConstr.constant = superView.frame.size.height;
        
        [UIView animateWithDuration:0.2 animations:^{
            [superView layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            self.hidden = YES;
            if (block) {
                block();
            }
        }];
    }
}

// 显示menuView,并在显示动画执行完毕回调block
- (void)showMenuView:(void(^)())block {
    UIView *superView = self.superview;
    if (superView) {
        
        self.hidden = NO;
        
        self.selfTopConstr.constant = 0.0;
        [UIView animateWithDuration:0.2 animations:^{
            
            [superView layoutIfNeeded];
            
        } completion:^(BOOL finished) {
            self.maskView.hidden = NO;
            if (block) {
                block();
            }
        }];
    }
    
}



// 隐藏menuView
- (void)dismissMenuView {
    
    [self dismissMenuView:nil];
}

// 显示Action
- (void)showMenuView {
    [self showMenuView:nil];    
}


- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.contentView.backgroundColor = self.separatorColor;
        self.maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
        [self.fastExportBtn setTitle:@"快速导出" forState:UIControlStateNormal];
        self.fastExportBtn.tag = XYMenuViewBtnTypeFastExport;
        [self.fastExportBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.hdExportBtn setTitle:@"高清导出" forState:UIControlStateNormal];
        self.hdExportBtn.tag = XYMenuViewBtnTypeHDExport;
        [self.hdExportBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.superclearBtn setTitle:@"超清导出" forState:UIControlStateNormal];
        self.superclearBtn.tag = XYMenuViewBtnTypeSuperClear;
        [self.superclearBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        self.cancelBtn.tag = XYMenuViewBtnTypeCancel;
        [self.cancelBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        __weak typeof(self) weakSelf = self;
        [self.cancelBtn xy_buttonClickBlock:^(UIButton *btn) {
                
                [weakSelf dismissMenuView];
        }];
        
        [self.maskView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMaskEvent)]];
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        self.maskView.translatesAutoresizingMaskIntoConstraints = NO;
        self.fastExportBtn.translatesAutoresizingMaskIntoConstraints = NO;
        self.hdExportBtn.translatesAutoresizingMaskIntoConstraints = NO;
        self.superclearBtn.translatesAutoresizingMaskIntoConstraints = NO;
        self.cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)layoutSubviews {

    [super layoutSubviews];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_contentView, _fastExportBtn, _hdExportBtn, _superclearBtn, _cancelBtn, _maskView);

    NSDictionary *metrics = @{@"margin": @1, @"marginC": @5, @"height": @(self.itemHeight)};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_maskView]|" options:kNilOptions metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_contentView]|" options:kNilOptions metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_maskView][_contentView]|" options:kNilOptions metrics:metrics views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_fastExportBtn]|" options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_hdExportBtn]|" options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_superclearBtn]|" options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_cancelBtn]|" options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_fastExportBtn(height)]-margin-[_hdExportBtn(height)]-margin-[_superclearBtn(height)]-marginC-[_cancelBtn(height)]|" options:kNilOptions metrics:metrics views:views]];
    
    [self layoutIfNeeded];
    
    
}


- (void)dealloc {

    NSLog(@"%s", __func__);
}

#pragma mark - Actions
- (void)tapOnMaskEvent {
    
    [self dismissMenuView];
}

- (void)btnClick:(UIButton *)btn {
    if (self.menuViewClickBlock) {
        self.menuViewClickBlock(btn.tag);
    }
}

#pragma mark - lazy loading
- (UIView *)maskView {
    if (_maskView == nil) {
        UIView *maskView = [[UIView alloc] init];
        [self addSubview:maskView];
        _maskView = maskView;
    }
    return _maskView;
}

- (UIView *)contentView {
    if (_contentView == nil) {
        UIView *contentView = [[UIView alloc] init];
        [self addSubview:contentView];
        _contentView = contentView;
    }
    return _contentView;
    
}
- (UIButton *)fastExportBtn {
    if (_fastExportBtn == nil) {
        [UIButton xy_button:^(UIButton *btn) {
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor whiteColor];
            [self.contentView addSubview:btn];
            _fastExportBtn = btn;
            
        }];
    }
    return _fastExportBtn;
}

- (UIButton *)hdExportBtn {
    if (_hdExportBtn == nil) {
        [UIButton xy_button:^(UIButton *btn) {
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor whiteColor];
            [self.contentView addSubview:btn];
            _hdExportBtn = btn;
           
        }];

    }
    return _hdExportBtn;
}

- (UIButton *)superclearBtn {
    if (_superclearBtn == nil) {
            
        [UIButton xy_button:^(UIButton *btn) {
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor whiteColor];
            [self.contentView addSubview:btn];
            _superclearBtn = btn;
            
            
        }];


    }
    return _superclearBtn;
}

- (UIButton *)cancelBtn {
    
    if (_cancelBtn == nil) {
        
        [UIButton xy_button:^(UIButton *btn) {
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor whiteColor];
            [self.contentView addSubview:btn];
            _cancelBtn = btn;
            
        }];
    }
    return _cancelBtn;
}

- (CGFloat)itemHeight {

    return _itemHeight ?: 60;
}

- (UIColor *)separatorColor {

    return _separatorColor ?: [UIColor colorWithWhite:240/255.0 alpha:1.0];
}

@end
