//
//  OSPhoneNumberModel.m
//  FileManagerShareExtension
//
//  Created by Swae on 2017/11/11.
//  Copyright © 2017年 alpface. All rights reserved.
//

#import "OSPhoneNumberModel.h"
#import "OSPhoneUtils.h"

@implementation OSPhoneNumberModel

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber label:(NSString *)label
{
    self = [super init];
    if (self != nil)
    {
        _phoneNumber = [OSPhoneUtils cleanInternationalPhone:phoneNumber forceInternational:false];
        _displayPhoneNumber = [OSPhoneUtils formatPhone:_phoneNumber forceInternational:false];
        _label = label;
    }
    return self;
}

@end

@implementation OSContactModel

- (instancetype)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName phoneNumbers:(NSArray *)phoneNumbers
{
    self = [super init];
    if (self != nil)
    {
        _firstName = firstName;
        _lastName = lastName;
        _phoneNumbers = phoneNumbers;
    }
    return self;
}

@end
