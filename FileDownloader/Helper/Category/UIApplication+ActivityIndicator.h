//
//  UIApplication+ActivityIndicator.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

@interface UIApplication (ActivityIndicator)

- (void)retainNetworkActivityIndicator;
- (void)releaseNetworkActivityIndicator;

@end
