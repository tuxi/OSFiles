//
//  ZWDatabaseQueue.h
//  WebBrowser
//
//  Created by Null on 2017/4/6.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "FMDatabaseQueue.h"
#import "ZWSQLiteHeader.h"
#import "ZWDatabase.h"

@interface ZWDatabaseQueue : FMDatabaseQueue

- (void)inZWDatabase:(void (^)(ZWDatabase *))block;

@end
