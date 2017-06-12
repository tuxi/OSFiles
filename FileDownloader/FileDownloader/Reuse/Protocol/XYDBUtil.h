//
//  XYDBUtil.h
//  
//
//  Created by mofeini on 17/2/10.
//  Copyright © 2017年 com.test.demo. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface XYDBUtilItem : NSObject

@property (strong, nonatomic) NSString *xy_itemId;
@property (strong, nonatomic) id xy_itemObject;
@property (strong, nonatomic) NSDate *xy_createdTime;

@end


@interface XYDBUtil : NSObject

/**
 *  根据dbName初始化数据库
 */
- (id)initDBWithName:(NSString *)dbName;

/**
 *  根据dbPath初始化数据库
 */
- (id)initWithDBWithPath:(NSString *)dbPath;

/**
 *  根据tableName创建数据表
 */
- (void)xy_createTableWithName:(NSString *)tableName;

/**
 *  清空数据表
 */
- (void)xy_clearTable:(NSString *)tableName;

/**
 *  tableName是否存在
 */
- (BOOL)xy_isExistTableWithName:(NSString *)tableName;

/**
 *  删除表
 */
- (BOOL)xy_deleteTable:(NSString *)tableName;

/**
 *  删除数据库
 */
- (void)xy_deleteDatabseWithDBName:(NSString *)DBName;

/**
 *  获得数据库存储路径
 */
- (NSString *)xy_getDBPath;

/**
 *  关闭数据库
 */
- (void)xy_close;

///************************ Put&Get methods *****************************************

- (void)xy_putObject:(id)object withId:(NSString *)objectId intoTable:(NSString *)tableName;

- (id)xy_getObjectById:(NSString *)objectId fromTable:(NSString *)tableName;

- (XYDBUtilItem *)xy_getDBItemById:(NSString *)objectId fromTable:(NSString *)tableName;

- (void)xy_putString:(NSString *)string withId:(NSString *)stringId intoTable:(NSString *)tableName;

- (NSString *)xy_getStringById:(NSString *)stringId fromTable:(NSString *)tableName;

- (void)xy_putNumber:(NSNumber *)number withId:(NSString *)numberId intoTable:(NSString *)tableName;

- (NSNumber *)xy_getNumberById:(NSString *)numberId fromTable:(NSString *)tableName;

- (NSArray *)xy_getAllItemsFromTable:(NSString *)tableName;

- (void)xy_deleteObjectById:(NSString *)objectId fromTable:(NSString *)tableName;

- (void)xy_deleteObjectsByIdArray:(NSArray *)objectIdArray fromTable:(NSString *)tableName;

- (void)xy_deleteObjectsByIdPrefix:(NSString *)objectIdPrefix fromTable:(NSString *)tableName;

- (NSArray *)xy_getItemsFromTable:(NSString *)tableName withRange:(NSRange)range;

@end
