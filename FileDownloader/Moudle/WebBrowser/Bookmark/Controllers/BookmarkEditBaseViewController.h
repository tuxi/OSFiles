//
//  BookmarkEditBaseViewController.h
//  WebBrowser
//
//  Created by Null on 2017/5/10.
//  Copyright © 2017年 Null. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BookmarkDataManager;

typedef void(^BookmarkEditCompletion)(void);
extern NSString *const kBookmarkEditTextFieldCellIdentifier;

@interface BookmarkEditBaseViewController : UIViewController

@property (nonatomic, copy) BookmarkEditCompletion completion;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, strong) BookmarkDataManager *dataManager;

- (void)initUI;
- (void)exit;

@end
