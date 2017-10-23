//
//  BookmarkItemEditViewController.h
//  WebBrowser
//
//  Created by Null on 2017/5/10.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "BookmarkEditBaseViewController.h"

@class BookmarkItemModel;

typedef NS_ENUM(NSUInteger, BookmarkItemOperationKind) {
    BookmarkItemOperationKindItemAdd,
    BookmarkItemOperationKindItemEdit
};

@interface BookmarkItemEditViewController : BookmarkEditBaseViewController

@property (nonatomic, strong) NSIndexPath *finalIndexPath;

- (instancetype)initWithDataManager:(BookmarkDataManager *)dataManager item:(BookmarkItemModel *)item sectionIndex:(NSIndexPath *)indexPath operationKind:(BookmarkItemOperationKind)kind completion:(BookmarkEditCompletion)completion;

@end
