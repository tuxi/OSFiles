//
//  UIApplication+ActivityIndicator.h
//  DownloaderManager
//
//  Created by alpface on 2017/6/4.
//  Copyright © 2017年 alpface. All rights reserved.
//

@interface UIApplication (ActivityIndicator)

- (void)retainNetworkActivityIndicator;
- (void)releaseNetworkActivityIndicator;

@end
