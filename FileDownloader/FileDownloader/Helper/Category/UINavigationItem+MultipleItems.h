//
//  UIBarButtonItem+MultipleItems.h
//  DownloaderManager
//
//  Created by Ossey on 2017/6/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef enum {
    UINavigationItemPositionLeft,
    UINavigationItemPositionRight
} UINavigationItemPosition;

@interface UINavigationItem (MultipleItems)

- (void)addLeftBarButtonItem:(UIBarButtonItem *)item atPosition:(UINavigationItemPosition)position;
- (void)addRightBarButtonItem:(UIBarButtonItem *)item atPosition:(UINavigationItemPosition)position;

- (void)removeLeftBarButtonItem:(UIBarButtonItem *)item;
- (void)removeRightBarButtonItem:(UIBarButtonItem *)item;
- (void)removeBarButtonItem:(UIBarButtonItem *)item;

@end
