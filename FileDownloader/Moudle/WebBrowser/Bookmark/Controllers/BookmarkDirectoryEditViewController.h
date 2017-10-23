//
//  BookmarkEditViewController.h
//  WebBrowser
//
//  Created by Null on 2017/5/7.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "BookmarkEditBaseViewController.h"

@class BookmarkDataManager;

typedef NS_ENUM(NSUInteger, BookmarkOperationKind) {
    BookmarkOperationKindSectionAdd,
    BookmarkOperationKindSectionEdit
};

@interface BookmarkDirectoryEditViewController : BookmarkEditBaseViewController

@property (nonatomic, assign) BookmarkOperationKind operationKind;

- (instancetype)initWithDataManager:(BookmarkDataManager *)dataManager completion:(BookmarkEditCompletion)completion;
- (instancetype)initWithDataManager:(BookmarkDataManager *)dataManager sectionName:(NSString *)sectionName sectionIndex:(NSIndexPath *)indexPath completion:(BookmarkEditCompletion)completion;

@end
