//
//  RTHelper.m
//  RFAPI
//
//  Created by BB9z on 2020/1/9.
//  Copyright © 2020 RFUI. All rights reserved.
//

#import "RTHelper.h"

@implementation RTHelper

+ (BOOL)catchException:(NS_NOESCAPE void(^)(void))tryBlock error:(NSError *__autoreleasing*)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
