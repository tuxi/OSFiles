//
//  UINavigationController+OSProgressBar.m
//  ProgressBarDemo
//
//  Created by Ossey on 15/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import "UINavigationController+OSProgressBar.h"


@implementation UINavigationController (OSProgressBar)

@dynamic progressView;

- (OSProgressView *)progressView {
    
    NSUInteger foundIndex = [self.navigationBar.subviews indexOfObjectPassingTest:^BOOL(__kindof UIView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [subview isKindOfClass:[OSProgressView class]];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    
    if (foundIndex != NSNotFound) {
        return self.navigationBar.subviews[foundIndex];
    }
    
    CGFloat defaultHeight = 2.0;
    CGRect frame = CGRectMake(0,
                              self.navigationBar.frame.size.height - defaultHeight,
                              self.navigationBar.frame.size.width,
                              defaultHeight);
    OSProgressView *progressView = [[OSProgressView alloc] initWithFrame:frame];
    [self.navigationBar addSubview:progressView];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    return progressView;
}



@end
