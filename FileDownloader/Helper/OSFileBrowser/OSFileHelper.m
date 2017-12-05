//
//  OSFileHelper.m
//  FileDownloader
//
//  Created by swae on 2017/12/4.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileHelper.h"
#import "OSFile.h"

@implementation OSFileHelper

+ (NSArray<OSFile *> *)sortByPinYinWithArray:(NSArray<OSFile *> *)toSortArray {
    //将传入数组转换为可变数组
    NSMutableArray<OSFile *> *needSortArray = [NSMutableArray arrayWithArray:toSortArray];
    //存储对应字母开头的所有数据的数组
    NSMutableArray *classifiedArray = [[NSMutableArray alloc] init];
    
    for(int i='A';i<='Z';i++){
        NSMutableArray *rulesArray = [[NSMutableArray alloc] init];
        NSString *indexString = [NSString stringWithFormat:@"%c",i];
        for(int j = 0; j < needSortArray.count; j++){
            OSFile *file = [needSortArray objectAtIndex:j];
            
            if([[self toPinyin: file.displayName] isEqualToString:indexString]){
                // 把file.displayName首字母相同的放到同一个数组里面
                [rulesArray addObject:file];
                [needSortArray removeObject:file];
                j--;
            }
        }
        if (rulesArray.count !=0) {
            [classifiedArray addObject:rulesArray];
        }
        
        if (needSortArray.count == 0) {
            break;
        }
    }
    
    // 剩下的就是非字母开头数据，加在classifiedArray的后面
    if (needSortArray.count !=0) {
        [classifiedArray addObject:needSortArray];
    }
    
    // 最后再分别对每个数组排序
    NSMutableArray *sortCompleteArray = [NSMutableArray array];
    for (NSArray *tempArray in classifiedArray) {
        NSArray *sortedElement = [tempArray sortedArrayUsingFunction:displayNameSort context:NULL];
        [sortCompleteArray addObject:sortedElement];
    }
    // sortCompleteArray就是最后排好序的二维数组了
    NSArray *resultArray = [sortCompleteArray valueForKeyPath:@"@unionOfArrays.self"];
    return resultArray;
}

NS_INLINE NSInteger displayNameSort(OSFile *file1, OSFile *file2, void *context) {
    return  [file1.displayName localizedCompare:file2.displayName];
}


+ (NSString *)toPinyin:(NSString *)str {
    NSMutableString *ms = [[NSMutableString alloc]initWithString:str];
    if (CFStringTransform((__bridge CFMutableStringRef)ms, 0,kCFStringTransformMandarinLatin, NO)) {
    }
    // 去除拼音的音调
    if (CFStringTransform((__bridge CFMutableStringRef)ms, 0,kCFStringTransformStripDiacritics, NO)) {
        if (str.length) {
            NSString *bigStr = [ms uppercaseString];
            NSString *cha = [bigStr substringToIndex:1];
            return cha;
        }
    }
    return str;
}

+ (NSArray<OSFile *> *)sortByCreateDateWithArray:(NSArray<OSFile *> *)toSortArray {
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES];
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithObjects:&sorter count:1];
    NSArray *sortArray = [toSortArray sortedArrayUsingDescriptors:sortDescriptors];
    return sortArray;
}


@end
