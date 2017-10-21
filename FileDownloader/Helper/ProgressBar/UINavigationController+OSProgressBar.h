//
//  UINavigationController+OSProgressBar.h
//  ProgressBarDemo
//
//  Created by Ossey on 15/08/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OSProgressView.h"

@interface UINavigationController (OSProgressBar)

@property (nonatomic, readonly) OSProgressView *progressView;

@end
