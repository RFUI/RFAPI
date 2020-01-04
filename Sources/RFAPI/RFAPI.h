/*
 RFAPI

 Copyright © 2014-2016, 2018-2020 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import <RFKit/RFRuntime.h>
#import <RFInitializing/RFInitializing.h>
#import "RFAPIDefine.h"
#import "RFAPIDefineManager.h"

@class AFNetworkReachabilityManager;
@class AFSecurityPolicy;
@protocol AFMultipartFormData;

@class RFMessageManager;
@class RFHTTPRequestFormData;
@protocol RFAPIModelTransformer;
@class RFNetworkActivityMessage;

@class RFAPIRequestConext;

@protocol RFAPITask
@required
@property (readonly, nonnull) RFAPIDefine *define;

/// This property is the dictionary pass through the request context.
@property (nullable) NSDictionary *userInfo;
- (void)cancel;
@end

typedef void(^RFAPIRequestProgressBlock)(id<RFAPITask> __nonnull task, NSProgress *__nonnull progress);
typedef void(^RFAPIRequestSuccessCallback)(id<RFAPITask> __nonnull task, id __nullable responseObject);
typedef void(^RFAPIRequestFailureCallback)(id<RFAPITask> __nullable task, NSError *__nonnull error);
typedef void(^RFAPIRequestCompletionCallback)(id<RFAPITask> __nullable task, BOOL success);

@interface RFAPI : NSObject <
    RFInitializing
>

#if !TARGET_OS_WATCH
/**
 The network reachability manager. Default value is the `sharedManager`.
 */
@property (null_resettable, nonatomic) AFNetworkReachabilityManager *reachabilityManager;
#endif

/**
 The dispatch queue serialize response. Default is a private concurrent queue.
 */
@property (null_resettable, nonatomic) dispatch_queue_t processingQueue;

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (null_resettable, nonatomic) dispatch_queue_t completionQueue;

/**
 The dispatch group for `completionBlock`. If `NULL` (default), a private dispatch group is used.
 */
@property (null_resettable, nonatomic) dispatch_group_t completionGroup;

#pragma mark - Define

@property (readonly, nonnull) RFAPIDefineManager *defineManager;

#pragma mark - Request management

- (nonnull NSArray<id> *)operationsWithIdentifier:(nullable NSString *)identifier;
- (nonnull NSArray<id> *)operationsWithGroupIdentifier:(nullable NSString *)identifier;

- (void)cancelOperationWithIdentifier:(nullable NSString *)identifier;
- (void)cancelOperationsWithGroupIdentifier:(nullable NSString *)identifier;

#pragma mark - Activity Indicator

#if !TARGET_OS_WATCH
@property (nullable) __kindof RFMessageManager *networkActivityIndicatorManager;
#endif

#pragma mark - Request

@property (nullable) Class requestConextClass;


- (nullable id<RFAPITask>)requestWithName:(nonnull NSString *)APIName context:(NS_NOESCAPE void (^__nullable)(__kindof RFAPIRequestConext *__nonnull))contextBlock NS_SWIFT_NAME(request(name:context:));

- (nullable id<RFAPITask>)requestWithDefine:(nonnull RFAPIDefine *)APIDefine context:(NS_NOESCAPE void (^__nullable)(__kindof RFAPIRequestConext *__nonnull))contextBlock NS_SWIFT_NAME(request(define:context:));

#pragma mark - Response

@property (nullable) id<RFAPIModelTransformer> modelTransformer;

// todo: 和 processingQueue 队列合一?
/**
 If `NULL` (default), the main queue will be used.
 */
@property (null_resettable, nonatomic) dispatch_queue_t responseProcessingQueue;

#pragma mark - Methods for overwrite

/**
 Default implementation first add parameters from APIDefine then add parameters from define manager.
 */
- (void)preprocessingRequestParameters:(NSMutableDictionary *__nullable __strong *__nonnull)parametersRef HTTPHeaders:(NSMutableDictionary *__nullable __strong *__nonnull)httpHeadersRef withParameters:(nullable NSDictionary *)parameters define:(nonnull RFAPIDefine *)define context:(nonnull RFAPIRequestConext *)context NS_SWIFT_NAME(preprocessingRequest(parametersRef:httpHeadersRef:parameters:define:context:));


/**
 The default implementation apply `requestCustomization` of the request context.
 */
- (nonnull NSMutableURLRequest *)finalizeSerializedRequest:(nonnull NSMutableURLRequest *)request withDefine:(nonnull RFAPIDefine *)define context:(nonnull RFAPIRequestConext *)context NS_SWIFT_NAME(finalizeSerializedRequest(_:define:context:));

/**
 默认实现返回 YES
 
 This method is called on the processing queue.

 @return 返回 YES 将继续错误的处理继续交由请求的回调处理，NO 处理结束
 */
- (BOOL)generalHandlerForError:(nonnull NSError *)error withDefine:(nonnull RFAPIDefine *)define task:(nonnull id<RFAPITask>)task failureCallback:(nullable RFAPIRequestFailureCallback)failure NS_SWIFT_NAME(generalHandlerForError(_:define:task:failure:));

/**
 判断响应是否是成功的结果
 
 Default implementation just return YES.
 
 This method is called on responseProcessingQueue.
 
 @param responseObjectRef 可以用来修改返回值
 @param error 可选的错误信息
 */
- (BOOL)isSuccessResponse:(id _Nullable __strong *_Nonnull)responseObjectRef error:(NSError *_Nullable __autoreleasing *_Nullable)error NS_SWIFT_NOTHROW;

@end


FOUNDATION_EXTERN NSString *_Nonnull const RFAPIRequestArrayParameterKey;
FOUNDATION_EXTERN NSString *_Nonnull const RFAPIRequestForceQuryStringParametersKey;
FOUNDATION_EXTERN NSErrorDomain _Nonnull const RFAPIErrorDomain;

@interface RFAPIRequestConext : NSObject

/// The parameters to be encoded.
/// If you want to send an array parameters, set `RFAPIRequestArrayParameterKey` key with the array.
@property (nullable) NSDictionary<NSString *, id> *parameters;

/// Use this block to appends data to the HTTP body.
@property (nullable) void (^formData)(id <AFMultipartFormData> __nonnull);

/// A dictionary of additional headers to send with requests.
@property (nullable) NSDictionary *HTTPHeaders;

/// Customization URL request object
@property (nullable) NSMutableURLRequest *__nonnull (^requestCustomization)(NSMutableURLRequest *__nonnull request);

/// Identifier for request. If `nil`, the api name will be used.
@property (nullable) NSString *identifier;

/// Group identifier for request.
@property (nullable) NSString *groupIdentifier;

/// An activity message to be displayed durning the request executing.
@property (nullable) RFNetworkActivityMessage *activityMessage;

@property (nullable) NSString *loadMessage;
@property BOOL loadMessageShownModal;

/// A block object to be executed when the upload progress is updated.
/// Note this block is called on the session queue, not the main queue.
@property (nullable) RFAPIRequestProgressBlock uploadProgress;

/// A block object to be executed when the download progress is updated.
/// Note this block is called on the session queue, not the main queue.
@property (nullable) RFAPIRequestProgressBlock downloadProgress;

/// A block object to be executed when the request finishes successfully.
@property (nullable) RFAPIRequestSuccessCallback success;

/// A block object to be executed when the request finishes unsuccessfully.
@property (nullable) RFAPIRequestFailureCallback failure;

/// A block object to be executed when the request is complated.
@property (nullable) RFAPIRequestCompletionCallback complation;
// todo: end callback and complate handler

@property (nullable) NSDictionary *userInfo;

@end
