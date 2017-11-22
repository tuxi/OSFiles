//
//  NSString+OSContainsEeachCharacter.m
//  FileBrowser
//
//  Created by Swae on 2017/11/20.
//  Copyright © 2017年 xiaoyuan. All rights reserved.
//

#import "NSString+OSContainsEeachCharacter.h"

@implementation NSString (OSContainsEeachCharacter)


- (BOOL)containsEachCharacter:(NSString *)string {
    return [self containsEachCharacter:string options:NSCaseInsensitiveSearch];
}

- (BOOL)containsEachCharacter:(NSString *)string options:(NSStringCompareOptions)options {
    return [self containsEachCharacter:string options:NSCaseInsensitiveSearch withStringContainsOptions:StringContainsLiteralRepeatSensitive];
}

- (BOOL)containsEachCharacter:(NSString *)string options:(NSStringCompareOptions)options withStringContainsOptions:(StringContains)containsOptions {
    BOOL orderSensitive = containsOptions & StringContainsOrderSensitive;
    BOOL literalRepeatSensitive = containsOptions & StringContainsLiteralRepeatSensitive;
    
    NSRange rangeWholeMatched = [self rangeOfString:string options:options];
    if (rangeWholeMatched.location != NSNotFound) {
        return YES;
    }
    
    // order sensitive
    NSInteger startLocation = 0;
    if (orderSensitive) {
        for (int i = 0; i < [string length]; i++) {
            NSString *str = [NSString stringWithFormat:@"%C", [string characterAtIndex:i]];
            NSRange range = [[self substringFromIndex:startLocation] rangeOfString:str options:options];
            if (range.location == NSNotFound) {
                return NO;
            } else {
                startLocation += (range.location + range.length);
            }
        }
    }
    // literal repeat sensitive
    if (literalRepeatSensitive) {
        NSArray *rangeArray = [self rangeArrayOfEachCharacter:string];
        return rangeArray.count == [string length];
    }
    return YES;
}

- (NSArray<NSValue *> *)rangeArrayOfEachCharacter:(NSString *)string options:(NSStringCompareOptions)options {
    NSMutableArray *mArr = [NSMutableArray array];
    NSRange rangeWholeMatched = [self rangeOfString:string options:options];
    if (rangeWholeMatched.location != NSNotFound) {
        return @[[NSValue valueWithBytes:&rangeWholeMatched objCType:@encode(NSRange)]];
    }
    for (int i = 0; i < [string length]; i++) {
        NSString *str = [NSString stringWithFormat:@"%C", [string characterAtIndex:i]];
        NSRange range = [self rangeOfString:str options:options];
        if (range.location == NSNotFound) {
            return @[];
        } else {
            NSValue *value = [NSValue valueWithBytes:&range objCType:@encode(NSRange)];
            NSInteger preLength = range.location + range.length;
            while (value != nil && [mArr containsObject:value]) {
                range = [[self substringFromIndex:preLength] rangeOfString:str options:options];
                if (range.location == NSNotFound) {
                    value = nil;
                } else {
                    NSRange rangeNext = NSMakeRange(range.location + preLength, range.length);
                    value = [NSValue valueWithBytes:&rangeNext objCType:@encode(NSRange)];
                    preLength += (range.location + range.length);
                }
            }
            if (value) {
                [mArr addObject:value];
            }
        }
    }
    return [mArr copy];
}

- (NSArray<NSValue *> *)rangeArrayOfEachCharacter:(NSString *)string {
    return [self rangeArrayOfEachCharacter:string options:NSCaseInsensitiveSearch];
}


@end
