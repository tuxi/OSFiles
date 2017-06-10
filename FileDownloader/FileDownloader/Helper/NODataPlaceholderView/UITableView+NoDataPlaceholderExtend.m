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


#pragma mark - <NoDataPlaceholderDataSource>

- (NSAttributedString *)titleAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView {
    NSString *text = nil;
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    text = @"没有关注的好友!";
    font = [UIFont boldSystemFontOfSize:18.0];
    textColor = [UIColor redColor];
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
}

- (NSAttributedString *)detailAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView {
    NSString *text = nil;
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    NSMutableDictionary *attributeDict = [NSMutableDictionary new];
    
    NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    
    text = @"快去关注你喜欢的达人吧! TA的最新动态将在本页中展示！";
    font = [UIFont systemFontOfSize:16.0];
    textColor = [UIColor greenColor];
    style.lineSpacing = 4.0;
    [attributeDict setObject:font forKey:NSFontAttributeName];
    [attributeDict setObject:textColor forKey:NSForegroundColorAttributeName];
    [attributeDict setObject:style forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributeDict];
    
    return attributedString;
    
}

- (NSAttributedString *)reloadbuttonTitleAttributedStringForNoDataPlaceholder:(UIScrollView *)scrollView forState:(UIControlState)state {
    
    NSString *text = nil;
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    text = @"获取达人";
    font = [UIFont systemFontOfSize:15.0];
    textColor = [UIColor blackColor];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
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
    return 0;
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
