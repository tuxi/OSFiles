//
//  UITableView+NoDataPlaceholderExtend.m
//  MVVMDemo
//
//  Created by Ossey on 2017/5/30.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UITableView+NoDataPlaceholderExtend.h"
#import <objc/runtime.h>

@interface UITableView () 

@end

@implementation UITableView (NoDataPlaceholderExtend)

#pragma mark - ~~~~~~~~~~~~~~~~~~~~~~~ Public ~~~~~~~~~~~~~~~~~~~~~~~


- (void)usingNoDataPlaceholder {
    self.loading = NO;
}


#pragma mark - <NoDataPlaceholderDataSource>

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView {
 
    return self.noDataPlaceholderTitleAttributedString;
    
}

- (NSAttributedString *)detailAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView {
    
    return self.noDataPlaceholderDetailAttributedString;
    
}

- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView forState:(UIControlState)state {
    
    return self.noDataPlaceholderReloadbuttonAttributedString;
}



- (UIImage *)imageForNoDataPlaceholder:(UIScrollView *)scrollView {
    if (self.loading) {
        return [UIImage imageNamed:@"loading_imgBlue_78x78" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
    } else {
        
        UIImage *image = [UIImage imageNamed:@"placeholder_instagram"];
        return image;
    }
}

- (UIColor *)reloadButtonBackgroundColorForNoDataPlaceholder:(UIScrollView *)scrollView {
    return [UIColor orangeColor];
}

- (CGFloat)contentOffsetYForNoDataPlaceholder:(UIScrollView *)scrollView {
    return -20;
}

- (CGFloat)contentSubviewsVerticalSpaceFoNoDataPlaceholder:(UIScrollView *)scrollView {
    return 30;
}


#pragma mark - <NoDataPlaceholderDelegate>

- (void)noDataPlaceholder:(UIScrollView *)scrollView didTapOnContentView:(nonnull UITapGestureRecognizer *)tap {
    if (self.reloadButtonClickBlock) {
        self.reloadButtonClickBlock();
    }
}

- (void)noDataPlaceholder:(UIScrollView *)scrollView didClickReloadButton:(UIButton *)button {
    
    if (self.reloadButtonClickBlock) {
        self.reloadButtonClickBlock();
    }
    
}


- (BOOL)noDataPlaceholderShouldAnimateImageView:(UIScrollView *)scrollView {
    return self.loading;
}

- (CAAnimation *)imageAnimationForNoDataPlaceholder:(UIScrollView *)scrollView {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    animation.toValue = [NSValue valueWithCATransform3D: CATransform3DMakeRotation(M_PI_2, 0.0, 0.0, 1.0) ];
    animation.duration = 0.25;
    animation.cumulative = YES;
    animation.repeatCount = MAXFLOAT;
    
    return animation;
}


- (UIView *)customViewForNoDataPlaceholder:(UIScrollView *)scrollview {
    if (self.isLoading) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        return activityView;
    }else {
        return nil;
    }
}

- (BOOL)noDataPlaceholderShouldAllowScroll:(UIScrollView *)scrollView {
    return YES;
}

#pragma mark - set \ get 

- (void)setLoading:(BOOL)loading {
    
    [super setLoading:loading];
    
    self.noDataPlaceholderDataSource = self;
    self.noDataPlaceholderDelegate = self;
    
    [self noDataPlaceholderExtend_setup];
    
    [self reloadNoDataView];
    
}

- (BOOL)isLoading {
    return [super isLoading];
}

- (void (^)())reloadButtonClickBlock {
    
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setReloadButtonClickBlock:(void (^)())reloadButtonClickBlock {
    objc_setAssociatedObject(self, @selector(reloadButtonClickBlock), reloadButtonClickBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setNoDataPlaceholderTitleAttributedString:(NSString *)noDataPlaceholderTitleAttributedString {
    objc_setAssociatedObject(self, @selector(noDataPlaceholderTitleAttributedString), noDataPlaceholderTitleAttributedString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)noDataPlaceholderTitleAttributedString {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNoDataPlaceholderDetailAttributedString:(NSString *)noDataPlaceholderDetailAttributedString {
    objc_setAssociatedObject(self, @selector(noDataPlaceholderDetailAttributedString), noDataPlaceholderDetailAttributedString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)noDataPlaceholderDetailAttributedString {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNoDataPlaceholderReloadbuttonAttributedString:(NSAttributedString *)noDataPlaceholderReloadbuttonAttributedString {
    objc_setAssociatedObject(self, @selector(noDataPlaceholderReloadbuttonAttributedString), noDataPlaceholderReloadbuttonAttributedString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSAttributedString *)noDataPlaceholderReloadbuttonAttributedString {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - Others

- (void)noDataPlaceholderExtend_setup {
     //在这个block块中设置传入的子控件属性，会导致这些子控件相关的数据源方法不再调用
//    __weak typeof(self) weakSelf = self;
//    [self setNoDataPlaceholderContentViewAttribute:^(UIButton *const  _Nonnull reloadBtn, UILabel *const  _Nonnull titleLabel, UILabel *const  _Nonnull detailLabel, UIImageView *const  _Nonnull imageView) {
//        
//        
//        // 设置reloadBtn
//        NSString *text = @"获取达人";
//        UIFont *font = [UIFont systemFontOfSize:15.0];
//        UIColor *textColor = [UIColor blackColor];
//        NSMutableDictionary *attributes = [NSMutableDictionary new];
//        [attributes setObject:font forKey:NSFontAttributeName];
//        [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
//        
//        NSAttributedString *reloadString = [[NSAttributedString alloc] initWithString:text attributes:attributes];
//        [reloadBtn setAttributedTitle:reloadString forState:UIControlStateNormal];
//        [reloadBtn setBackgroundColor:[UIColor orangeColor]];
//        reloadBtn.layer.cornerRadius = 8.8;
//        [reloadBtn.layer setMasksToBounds:YES];
//        
//        
//        // 设置titleLabel
//        [titleLabel setText:@"获取数据"];
//        // 设置detailLabel
//        [detailLabel setText:@"今天加载数据，没准可以找到你心仪的女神哦~~~~~~~~~~!"];
//        // 设置imageView
//        if (weakSelf.isLoading) {
//            [imageView setImage:[UIImage imageNamed:@"loading_imgBlue_78x78"]];
//            
//            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform"];
//            animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
//            animation.toValue = [NSValue valueWithCATransform3D: CATransform3DMakeRotation(M_PI_2, 0.0, 0.0, 1.0) ];
//            animation.duration = 0.25;
//            animation.cumulative = YES;
//            animation.repeatCount = MAXFLOAT;
//            
//            [imageView.layer addAnimation:animation forKey:@"animation"];
//        } else {
//            [imageView setImage:[UIImage imageNamed:@"placeholder_instagram"]];
//            [imageView.layer removeAnimationForKey:@"animation"];
//        }
//        
//        
//    }];
}

@end
