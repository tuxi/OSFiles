//
//  UIApplication+ActivityIndicator.m
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UIApplication+ActivityIndicator.h"

@implementation UIApplication (ActivityIndicator)

- (void)_updateNetworkActivityIndicator:(BOOL)visible {
    static NSInteger count = 0;
    
    if (visible) count += 1;
    else count -= 1;
    NSLog(@"INFO: NetworkActivityIndicatorCount: %@", @(count));
    [self setNetworkActivityIndicatorVisible:(count > 0)];
}


- (void)retainNetworkActivityIndicator {
    [self _updateNetworkActivityIndicator:YES];
}

- (void)releaseNetworkActivityIndicator {
    [self _updateNetworkActivityIndicator:NO];
}

@end
