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

 @return A define object with it's name.
 */
- (nullable RFAPIDefine *)defineForName:(nonnull RFAPIName)defineName;

@property (null_resettable, nonatomic) NSArray<RFAPIDefine *> *defines;

#pragma mark - Authorization values

@property (readonly, nonnull) NSMutableDictionary<NSString *, NSString *> *authorizationHeader;
@property (readonly, nonnull) NSMutableDictionary<NSString *, id> *authorizationParameters;

#pragma mark - RFAPI Support

/// Default is `AFJSONRequestSerializer`.
@property (null_resettable, nonatomic) id<AFURLRequestSerialization> defaultRequestSerializer;

/// Default is a `AFJSONResponseSerializer` with allow fragments option.
@property (null_resettable, nonatomic) id<AFURLResponseSerialization> defaultResponseSerializer;

- (nullable NSURL *)requestURLForDefine:(nonnull RFAPIDefine *)define parameters:(nullable NSMutableDictionary *)parameters error:(NSError *__nullable __autoreleasing *__nullable)error;

- (nonnull id<AFURLRequestSerialization>)requestSerializerForDefine:(nullable RFAPIDefine *)define;
- (nonnull id<AFURLResponseSerialization>)responseSerializerForDefine:(nullable RFAPIDefine *)define;

@end
