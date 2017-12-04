//
//  OSFileBrowserAppearanceConfigs.m
//  FileDownloader
//
//  Created by xiaoyuan on 04/12/2017.
//  Copyright © 2017 Ossey. All rights reserved.
//

#import "OSFileBrowserAppearanceConfigs.h"

static NSString * const OSFileBrowserAppearanceConfigsSortType = @"OSFileBrowserAppearanceConfigsSortType";
NSNotificationName const OSFileBrowserAppearanceConfigsSortTypeDidChangeNotification = @"OSFileBrowserAppearanceConfigsSortTypeDidChangeNotification";

@implementation OSFileBrowserAppearanceConfigs

+ (OSFileBrowserSortType)fileSortType {
    NSNumber *num = [[NSUserDefaults standardUserDefaults] objectForKey:OSFileBrowserAppearanceConfigsSortType];
    if (!num) {
        return OSFileBrowserSortTypeOrderA_To_Z;
    }
    return (OSFileBrowserSortType)[num integerValue];
}

+ (void)setFileSortType:(OSFileBrowserSortType)fileSortType {
    if (fileSortType == [self fileSortType]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(fileSortType) forKey:OSFileBrowserAppearanceConfigsSortType];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:OSFileBrowserAppearanceConfigsSortTypeDidChangeNotification object:@(fileSortType)];
}

@end
