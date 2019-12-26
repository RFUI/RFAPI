/*!
 RFAPIDefine
 RFAPI
 
 Copyright (c) 2014, 2018-2019 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */
#import <RFKit/RFRuntime.h>

@interface RFAPIDefine : NSObject <
    NSCopying,
    NSSecureCoding
>
/// Used to get a deine from a RFAPIDefineManager
@property (copy, nullable) NSString *name;

/// HTTP base URL
@property (copy, nullable, nonatomic) NSURL *baseURL;

///
@property (copy, nullable) NSString *pathPrefix;

///
@property (copy, nullable) NSString *path;

/// HTTP Method
@property (copy, nullable, nonatomic) NSString *method;

#pragma mark - Request

/// HTTP headers to append
@property (copy, nullable) NSDictionary *HTTPRequestHeaders;

/// Default HTTP request parameters
@property (copy, nullable) NSDictionary *defaultParameters;

/// If send authorization HTTP header or parameters
@property BOOL needsAuthorization;

/// AFURLRequestSerialization class
@property (nullable) Class requestSerializerClass;

#pragma mark - Cache

typedef NS_ENUM(short, RFAPIDefineCachePolicy) {
    RFAPICachePolicyDefault = 0,
    RFAPICachePolicyProtocol = 1,       /// 协议，现在未作特殊处理
    RFAPICachePolicyAlways = 2,         /// 缓存一次后总是返回缓存数据
    RFAPICachePolicyExpire = 3,         /// 一段时间内不再请求
    RFAPICachePolicyNoCache = 5         /// 无缓存，总是请求新数据
};
/// @warning unimplemented
@property RFAPIDefineCachePolicy cachePolicy;

/// Gives the date/time after which the cache is considered stale
/// @warning unimplemented
@property NSTimeInterval expire;

typedef NS_ENUM(short, RFAPIDefineOfflinePolicy) {
    RFAPIOfflinePolicyDefault = 0,       /// 不特殊处理
    RFAPIOfflinePolicyLoadCache = 1      /// 返回缓存数据
};
/// @warning unimplemented
@property RFAPIDefineOfflinePolicy offlinePolicy;

#pragma mark - Response

@property (nullable) Class responseSerializerClass;

typedef NS_ENUM(short, RFAPIDefineResponseExpectType) {
    // todo: add pass type
    RFAPIDefineResponseExpectDefault = 0,   /// 不特殊处理
    RFAPIDefineResponseExpectSuccess = 1,   /// Overwrite [RFAPI isSuccessResponse:error:] to  determine whether success or failure.
    RFAPIDefineResponseExpectObject  = 2,   /// Expect an object
    RFAPIDefineResponseExpectObjects = 3,   /// Expect an array of objects
};
///
@property RFAPIDefineResponseExpectType responseExpectType;

/// Accept null response
@property BOOL responseAcceptNull;

/// Expect JSONModel class
@property (nullable) Class responseClass;

#pragma mark - 

/// User info
@property (copy, nullable) NSDictionary *userInfo;

/// Comment
@property (copy, nullable) NSString *notes;
@end


#import "RFAPIDefineConfigFileKeys.h"

@interface RFAPIDefine (RFConfigFile)
- (nonnull instancetype)initWithRule:(nonnull NSDictionary<RFAPIDefineKey, id> *)rule name:(nonnull NSString *)name;
@end
