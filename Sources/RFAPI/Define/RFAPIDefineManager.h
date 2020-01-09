/*
 RFAPIDefineManager
 RFAPI
 
 Copyright © 2014-2016, 2018-2019 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import "RFAPIDefine.h"

@protocol AFURLRequestSerialization;
@protocol AFURLResponseSerialization;

@interface RFAPIDefineManager : NSObject

/**
 Returns the define object with the specified name.
 
 You cannot get default rule with this method.

 The return value is not copied. If you modify the return value, the instance in the define manager is also modified.

 @return A define object with it's name.
 */
- (nullable RFAPIDefine *)defineForName:(nonnull RFAPIName)defineName;

@property (nullable) RFAPIDefine *defaultDefine;

/**
 getter get defines in the define manager.

 setter update defines in the define manager. Passing `nil` has no effect.
 */
@property (copy, null_resettable, nonatomic) NSArray<RFAPIDefine *> *defines;

#pragma mark - Authorization

/// Additional HTTP headers sent with APIs that requires authorization.
@property (readonly, nonnull) NSMutableDictionary<NSString *, NSString *> *authorizationHeader;

/// Additional parameters sent with APIs that requires authorization.
@property (readonly, nonnull) NSMutableDictionary<NSString *, id> *authorizationParameters;

#pragma mark - Request

/// Default is `AFJSONRequestSerializer`.
@property (null_resettable, nonatomic) id<AFURLRequestSerialization> defaultRequestSerializer;

- (nonnull id<AFURLRequestSerialization>)requestSerializerForDefine:(nullable RFAPIDefine *)define;

- (nullable NSURL *)requestURLForDefine:(nonnull RFAPIDefine *)define parameters:(nullable NSMutableDictionary *)parameters error:(NSError *__nullable __autoreleasing *__nullable)error;

#pragma mark Response

/// Default is a `AFJSONResponseSerializer` with allow fragments option.
@property (null_resettable, nonatomic) id<AFURLResponseSerialization> defaultResponseSerializer;

- (nonnull id<AFURLResponseSerialization>)responseSerializerForDefine:(nullable RFAPIDefine *)define;

@end
