//
//  ZWDatabaseQueue.m
//  WebBrowser
//
//  Created by Null on 2017/4/6.
//  Copyright © 2017年 Null. All rights reserved.
//

#import "ZWDatabaseQueue.h"

@implementation ZWDatabaseQueue

- (void)inZWDatabase:(void (^)(ZWDatabase *))block{
    [super inDatabase:^(FMDatabase *db){
        if (block) {
            ZWDatabase *zwDB = (ZWDatabase *)db;
            block(zwDB);
        }
    }];
}

+ (Class)databaseClass{
    return [ZWDatabase class];
}

@end
