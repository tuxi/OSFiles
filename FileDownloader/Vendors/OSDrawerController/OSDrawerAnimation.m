//
//  OSDrawerAnimation.m
//  OSDrawerControllerSample
//
//  Created by Swae on 2017/11/15.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSDrawerAnimation.h"

static const CGFloat kDrawerCenterViewDestinationScale = 1.0;

@implementation OSDrawerAnimation


- (instancetype)init {
    self = [super init];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.animationDelay = 0.0;
    self.animationDuration = 0.7;
    self.initialSpringVelocity = 9.0;
    self.springDamping = 0.8;
}


- (void)presentationWithSide:(OSDrawerSide)drawerSide sideView:(UIView *)sideView centerView:(UIView *)centerView animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    void (^springAnimation)(void) = ^{
        [self applyTransformsWithSide:drawerSide sideView:sideView centerView:centerView];
    };
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                              delay:self.animationDelay
             usingSpringWithDamping:self.springDamping
              initialSpringVelocity:self.initialSpringVelocity
                            options:UIViewAnimationOptionCurveLinear
                         animations:springAnimation
                         completion:nil];
    } else {
        springAnimation();
    }
}

- (void)dismissWithSide:(OSDrawerSide)drawerSide sideView:(UIView *)sideView centerView:(UIView *)centerView animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    void (^springAnimation)(void) = ^{
        [self removeTransformsWithSide:drawerSide sideView:sideView centerView:centerView];
    };
    
    if (animated) {
        [UIView animateWithDuration:self.animationDuration
                              delay:self.animationDelay
             usingSpringWithDamping:self.springDamping
              initialSpringVelocity:self.initialSpringVelocity
                            options:UIViewAnimationOptionCurveLinear
                         animations:springAnimation completion:completion];
    } else {
        springAnimation();
    }
}


- (void)willRotateOpenDrawerWithOpenSide:(OSDrawerSide)drawerSide sideView:(UIView *)sideView centerView:(UIView *)centerView {
    
    
}

- (void)didRotateOpenDrawerWithOpenSide:(OSDrawerSide)drawerSide sideView:(UIView *)sideView centerView:(UIView *)centerView {
    void (^springAnimation)(void) = ^{
        [self applyTransformsWithSide:drawerSide sideView:sideView centerView:centerView];
    };
    
    [UIView animateWithDuration:self.animationDuration
                          delay:self.animationDelay
         usingSpringWithDamping:self.springDamping
          initialSpringVelocity:self.initialSpringVelocity
                        options:UIViewAnimationOptionCurveLinear
                     animations:springAnimation
                     completion:nil];
}


/**
 *  Move a view layer's anchor point and adjust the position so as to not move the layer. Be careful
 *  in using this. It has some side effects with orientation changes that need to be handled.
 *
 *  @param anchorPoint The anchor point being moved
 *  @param view        The view of who's anchor point is being moved
 */
- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {
    CGPoint newPoint = CGPointMake(view.bounds.size.width  * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    
    CGPoint oldPoint = CGPointMake(view.bounds.size.width  * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}


- (void)applyTransformsWithSide:(OSDrawerSide)drawerSide sideView:(UIView *)sideView centerView:(UIView *)centerView {
    [sideView layoutIfNeeded];
    [centerView layoutIfNeeded];
    CGFloat direction = drawerSide == OSDrawerSideLeft ? 1.0 : -1.0;
    CGFloat sideWidth = sideView.bounds.size.width;
    CGFloat centerWidth = centerView.bounds.size.width;
    CGFloat centerViewHorizontalOffset = direction * sideWidth;
    CGFloat scaledCenterViewHorizontalOffset = direction * (sideWidth - (centerWidth - kDrawerCenterViewDestinationScale * centerWidth) / 2.0);
    
    CGAffineTransform sideTranslate = CGAffineTransformMakeTranslation(centerViewHorizontalOffset, 0.0);
    sideView.transform = sideTranslate;
    
    
    CGAffineTransform centerTranslate = CGAffineTransformMakeTranslation(scaledCenterViewHorizontalOffset, 0.0);
    CGAffineTransform centerScale = CGAffineTransformMakeScale(kDrawerCenterViewDestinationScale, kDrawerCenterViewDestinationScale);
    centerView.transform = CGAffineTransformConcat(centerScale, centerTranslate);
}

- (void)removeTransformsWithSide:(OSDrawerSide)drawerSide sideView:(UIView *)sideView centerView:(UIView *)centerView {
    sideView.transform = CGAffineTransformIdentity;
    centerView.transform = CGAffineTransformIdentity;
}

@end
