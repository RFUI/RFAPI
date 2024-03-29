/*
 RFAPIDefine
 RFAPI
 
 Copyright © 2014, 2018-2020 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */
#import <RFKit/RFRuntime.h>

typedef NSString * RFAPIName NS_EXTENSIBLE_STRING_ENUM;

/**
 A define object is used to describe all aspects of an API: what the URL is, how to send the request sent, how to handle the response, and so on.
 */
@interface RFAPIDefine : NSObject <
    NSCopying,
    NSSecureCoding
>
/// Used to get a define from a RFAPIDefineManager
@property (copy, nullable) RFAPIName name;

/**
 HTTP base URL

 If there are other paths behind the host, a terminal slash should added at the end of the url.
 E.g: "http://example.com/base" is equal to "http://example.com", the correct one is "http://example.com/base/".
 */
@property (copy, nullable) NSURL *baseURL;

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
@property (nonatomic) BOOL needsAuthorization;

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
@property (nonatomic) RFAPIDefineCachePolicy cachePolicy;

/// Gives the date/time after which the cache is considered stale
/// @warning unimplemented
@property (nonatomic) NSTimeInterval expire;

typedef NS_ENUM(short, RFAPIDefineOfflinePolicy) {
    RFAPIOfflinePolicyDefault = 0,       /// 不特殊处理
    RFAPIOfflinePolicyLoadCache = 1      /// 返回缓存数据
};
/// @warning unimplemented
@property (nonatomic) RFAPIDefineOfflinePolicy offlinePolicy;

#pragma mark - Response

@property (nullable) Class responseSerializerClass;

typedef NS_ENUM(short, RFAPIDefineResponseExpectType) {
    RFAPIDefineResponseExpectDefault = 0,   /// 不特殊处理
    RFAPIDefineResponseExpectSuccess = 1,   /// Overwrite [RFAPI isSuccessResponse:error:] to  determine whether success or failure.
    RFAPIDefineResponseExpectObject  = 2,   /// Expect an object
    RFAPIDefineResponseExpectObjects = 3,   /// Expect an array of objects
};
///
@property (nonatomic) RFAPIDefineResponseExpectType responseExpectType;

/// Accept null response
@property (nonatomic) BOOL responseAcceptNull;

/// Expect class name
/// The model transformer uses this property to create special kind of model instances.
@property (nullable) NSString *responseClass;

#pragma mark - 

/// User info
@property (copy, nullable) NSDictionary *userInfo;

/// Comment
@property (copy, nullable) NSString *notes;

- (nonnull RFAPIDefine *)newDefineMergedDefault:(nonnull RFAPIDefine *)defaultDefine;

@end
