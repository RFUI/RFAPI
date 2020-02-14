//
//  RTHelper.h
//  RFAPI
//
//  Created by BB9z on 2020/1/9.
//  Copyright © 2020 RFUI. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
Helper methods for unit test.
*/
@interface RTHelper : NSObject

/**
 Help test cases written in Swift to catch NSException.
 */
+ (BOOL)catchException:(NS_NOESCAPE void(^__nonnull)(void))tryBlock error:(NSError *__nullable __autoreleasing *__nullable)error;

@end
