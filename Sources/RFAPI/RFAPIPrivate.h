/*
 Private Header
 RFAPI

 Copyright © 2019 BB9z
 https://github.com/RFUI/RFAPI

 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import "RFAPI.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <AFNetworking/AFSecurityPolicy.h>
#import <RFKit/dout.h>

#if RFDEBUG
#   define RFAPILogError_(DEBUG_ERROR, ...) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wformat-nonliteral\"") \
    dout_error(DEBUG_ERROR, __VA_ARGS__) \
    _Pragma("clang diagnostic pop")
#else
#   define RFAPILogError_(DEBUG_ERROR, ...)
#endif

@class _RFURLSessionManager, _RFAPISessionTask;
@class RFAPIDefineManager;

@interface RFAPI ()
@property (nullable) _RFURLSessionManager *_RFAPI_sessionManager;
@property (readonly, nonnull, nonatomic) _RFURLSessionManager *http;
@property (null_resettable, nonatomic) RFAPIDefineManager *defineManager;

- (void)_RFAPI_handleTaskComplete:(nonnull _RFAPISessionTask *)task response:(nullable NSURLResponse *)response data:(nullable NSData *)data  error:(nullable NSError *)error;

@end


@interface RFAPIDefine ()
@property (nullable) NSNumber *needsAuthorizationValue;
@property (nullable) NSNumber *cachePolicyValue;
@property (nullable) NSNumber *cacheExpireValue;
@property (nullable) NSNumber *offlinePolicyValue;
@property (nullable) NSNumber *responseExpectTypeValue;
@property (nullable) NSNumber *responseAcceptNullValue;
@end
