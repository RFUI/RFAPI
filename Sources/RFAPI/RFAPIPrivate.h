/*
 Private Header
 RFAPI

 Copyright © 2019 BB9z
 https://github.com/RFUI/RFAPI

 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import "RFAPI.h"
#import <RFKit/dout.h>

/// The localized string loaded from main bundle's default table.
extern NSString *__nonnull RFAPILocalizedString(NSString *__nonnull key, NSString *__nonnull value);

#if RFDEBUG
#   define RFAPILogError_(DEBUG_ERROR, ...) dout_error(DEBUG_ERROR, __VA_ARGS__)
#else
#   define RFAPILogError_(DEBUG_ERROR, ...)
#endif

@class _RFURLSessionManager, _RFAPISessionTask;
@class RFAPIDefineManager;

@interface RFAPI ()
@property (nullable) _RFURLSessionManager *_RFAPI_sessionManager;
@property (null_resettable, nonatomic) _RFURLSessionManager *http;
@property (null_resettable, nonatomic) RFAPIDefineManager *defineManager;

- (void)_RFAPI_handleTaskComplete:(nonnull _RFAPISessionTask *)task response:(nullable NSURLResponse *)response data:(nullable NSData *)data  error:(nullable NSError *)error;

@end
