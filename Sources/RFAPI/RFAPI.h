/*
 RFAPI

 Copyright © 2014-2016, 2018-2021 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import <RFKit/RFRuntime.h>
#import <RFInitializing/RFInitializing.h>
#import "RFAPIDefine.h"
#import "RFAPIDefineManager.h"
#import <AFNetworking/AFURLRequestSerialization.h>
#import <AFNetworking/AFURLResponseSerialization.h>

@class AFNetworkReachabilityManager;
@class AFSecurityPolicy;
@class RFAPIRequestConext;
@class RFMessageManager;
@class RFNetworkActivityMessage;
@protocol RFAPIModelTransformer;

@protocol RFAPITask
@required

/// API define object of current request.
@property (readonly, nonnull) RFAPIDefine *define;

/// Identifier string of current request.
@property (readonly, nonnull) NSString *identifier;

/// Group identifier string of current request.
@property (readonly, nullable) NSString *groupIdentifier;

/// The original request object passed when the task was created.
@property (readonly, copy, nullable, nonatomic) NSURLRequest *currentRequest;

/// The original request object passed when the task was created.
@property (readonly, copy, nullable, nonatomic) NSURLRequest *originalRequest;

/// The server’s response to the currently active request.
@property (readonly, copy, nullable, nonatomic) NSURLResponse *response;

/// Serialized response object from server response.
@property (nullable) id responseObject;

/// An error object that indicates why the task is unsuccessful.
@property (nullable) NSError *error;

/// Whether the request completed successfully.
@property (readonly) BOOL isSuccess;

/// This property is the dictionary pass through the request context.
@property (nullable) NSDictionary *userInfo;

/// Cancels the task.
- (void)cancel;
@end

typedef void(^RFAPIRequestProgressBlock)(id<RFAPITask> __nonnull task, NSProgress *__nonnull progress);
typedef void(^RFAPIRequestSuccessCallback)(id<RFAPITask> __nonnull task, id __nullable responseObject);
typedef void(^RFAPIRequestFailureCallback)(id<RFAPITask> __nullable task, NSError *__nonnull error);
typedef void(^RFAPIRequestFinishedCallback)(id<RFAPITask> __nullable task, BOOL success);
typedef void(^RFAPIRequestCombinedCompletionCallback)(id<RFAPITask> __nullable task, id __nullable responseObject, NSError *__nullable error);

/**
 Full-featured URL session wrapper designed for API requests.
 */
@interface RFAPI : NSObject <
    RFInitializing
>

#pragma mark Configurations before use

/**
 Used for reachabilityManager creation.
 Or when define does not have a baseURL when making a request.
 */
@property (nullable) NSURL *baseURL;

/**
 Used for url session creation. If the session object has been created, setting this property has no effect.
 */
@property (nullable, nonatomic) NSURLSessionConfiguration *sessionConfiguration;

#pragma mark -

#if !TARGET_OS_WATCH
/**
 The network reachability manager. Default value is the `sharedManager`.
 */
@property (null_resettable, nonatomic) AFNetworkReachabilityManager *reachabilityManager;
#endif

/**
 The dispatch queue serialize response. Default is a shared private concurrent queue.
 */
@property (null_resettable, nonatomic) dispatch_queue_t processingQueue;

/**
 The dispatch queue for `completionBlock`. Default value is the main queue.
 */
@property (null_resettable, nonatomic) dispatch_queue_t completionQueue;

/**
 The dispatch group for `completionBlock`. Default is a private dispatch group.
 */
@property (null_resettable, nonatomic) dispatch_group_t completionGroup;

#pragma mark -

@property (readonly, nonnull) RFAPIDefineManager *defineManager;

#if !TARGET_OS_WATCH
@property (nullable) __kindof RFMessageManager *networkActivityIndicatorManager;
#endif

/**
 The security policy used by created session to evaluate server trust for secure connections.

 Default is the `defaultPolicy`.
 */
@property (nullable, nonatomic) AFSecurityPolicy *securityPolicy;

#pragma mark - Request management

- (nonnull NSArray<id<RFAPITask>> *)operationsWithIdentifier:(nullable NSString *)identifier;
- (nonnull NSArray<id<RFAPITask>> *)operationsWithGroupIdentifier:(nullable NSString *)identifier;

- (void)cancelOperationWithIdentifier:(nullable NSString *)identifier;
- (void)cancelOperationsWithGroupIdentifier:(nullable NSString *)identifier;

#pragma mark - Request

@property (nullable) Class requestConextClass;


- (nullable id<RFAPITask>)requestWithName:(nonnull NSString *)APIName context:(NS_NOESCAPE void (^__nullable)(__kindof RFAPIRequestConext *__nonnull))contextBlock NS_SWIFT_NAME(request(name:context:));

- (nullable id<RFAPITask>)requestWithDefine:(nonnull RFAPIDefine *)APIDefine context:(NS_NOESCAPE void (^__nullable)(__kindof RFAPIRequestConext *__nonnull))contextBlock NS_SWIFT_NAME(request(define:context:));

#pragma mark - Response

@property (nullable) id<RFAPIModelTransformer> modelTransformer;

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
 Handle and progress all request errors in one place.

 Default implementation just return YES.
 
 This method is called on the completionQueue.

 @return Returning YES will continue error processing and continue with the callback processing of the request, if NO processing ends immediately.
 */
- (BOOL)generalHandlerForError:(nonnull NSError *)error withDefine:(nonnull RFAPIDefine *)define task:(nonnull id<RFAPITask>)task failureCallback:(nullable RFAPIRequestFailureCallback)failure NS_SWIFT_NAME(generalHandlerForError(_:define:task:failure:));

/**
 Determine if the response was a successful response.
 
 Default implementation just return YES.
 
 This method is called on the processingQueue.
 
 @param responseObjectRef Can be used to modify the response object.
 @param error Optional error.
 */
- (BOOL)isSuccessResponse:(id __nullable __strong *__nonnull)responseObjectRef error:(NSError *__nullable __autoreleasing *__nonnull)error NS_SWIFT_NOTHROW;

#pragma mark - Localization

/**
 Make localized error object.

 Localized version of strings reads from the default table in the main bundle.
 */
+ (nonnull NSError *)localizedErrorWithDoomain:(nonnull NSErrorDomain)domain code:(NSInteger)code underlyingError:(nullable NSError *)error descriptionKey:(nonnull NSString *)descriptionKey descriptionValue:(nonnull NSString *)descriptionValue reasonKey:(nullable NSString *)reasonKey reasonValue:(nullable NSString *)reasonValue suggestionKey:(nullable NSString *)suggestionKey suggestionValue:(nullable NSString *)suggestionValue url:(nullable NSURL *)url;

/**
 The localized string loaded from main bundle's default table.

 key and value must not be nil at the same time.
 */
+ (nonnull NSString *)localizedStringForKey:(nullable NSString *)key value:(nullable NSString *)value;

@end

/// Send array parameters
FOUNDATION_EXTERN NSString *__nonnull const RFAPIRequestArrayParameterKey;
/// Sent parameters through qury string
FOUNDATION_EXTERN NSString *__nonnull const RFAPIRequestForceQuryStringParametersKey;

/// Errors generated inside RFAPI
FOUNDATION_EXTERN NSErrorDomain __nonnull const RFAPIErrorDomain;

///
@interface RFAPIRequestConext : NSObject

/// The timeout interval for the request, in seconds.
/// If not set or its value is not greater than 0, the default timeout will be used.
@property NSTimeInterval timeoutInterval;

/**
 The parameters to be encoded.

 If you want to send an array parameters, set `RFAPIRequestArrayParameterKey` key with the array.
 If you want some parameters sent through qury string of the URL, set `RFAPIRequestForceQuryStringParametersKey` with a dictionary contains these parameters.
 */
@property (nullable) NSDictionary<NSString *, id> *parameters;

/// Use this block to appends data to the HTTP body.
@property (nullable) void (^formData)(id <AFMultipartFormData> __nonnull);

/// A dictionary of additional headers to send with requests.
@property (nullable) NSDictionary *HTTPHeaders;

/// Customization URL request object
@property (nullable) NSMutableURLRequest *__nonnull (^requestCustomization)(NSMutableURLRequest *__nonnull request);

/// Allow transform resesoinse object in the processing queue. The return value will become the final responseObject.
@property (nullable) id __nullable (^responseObjectTransformer)(RFAPIDefine *__nonnull define, id __nullable responseObject);

/// Identifier for request. If `nil`, the api name will be used.
@property (nullable) NSString *identifier;

/// Group identifier for request.
@property (nullable) NSString *groupIdentifier;

/// An activity message to be displayed during the request executing.
/// If the request is finished right after been make, eg. it has been already cached, the message will not be displayed.
@property (nullable) RFNetworkActivityMessage *activityMessage;

/// If not nil and the `activityMessage` is not be set, a message will be create automatically.
@property (nullable) NSString *loadMessage;
@property BOOL loadMessageShownModal;

/// A block object to be executed when the upload progress is updated.
/// Note this block is called on the session queue, not the main queue.
@property (nullable) RFAPIRequestProgressBlock uploadProgress;

/// A block object to be executed when the download progress is updated.
/// Note this block is called on the session queue, not the main queue.
@property (nullable) RFAPIRequestProgressBlock downloadProgress;

/**
 You could pass some UI elements here.

 For UIControl or any object response to `setEnabled:`, it will set enabled to NO when the request starts and restore to YES after request is finished.
 For UIRefreshControl, it will try call `beginRefreshing` when the request starts and `endRefreshing` after request is finished.
 For UIActivityIndicatorView, it will call `startAnimating` when the request starts and `stopAnimating` after request is finished.
 */
@property (nullable) NSArray<id> *bindControls;

/// A block object to be executed when the request finishes successfully.
@property (nullable) RFAPIRequestSuccessCallback success NS_SWIFT_NAME(successCallback);

/// A block object to be executed when the request finishes unsuccessfully.
/// It will not be called if the request is cancelled.
@property (nullable) RFAPIRequestFailureCallback failure NS_SWIFT_NAME(failureCallback);

/// A block object to be executed when the request is completed.
@property (nullable) RFAPIRequestFinishedCallback finished NS_SWIFT_NAME(finishedCallback);

/// A block object to be executed when the request is completed.
/// Error will be nil if the request is cancelled. At this time, you could get the error object on the task object.
@property (nullable) RFAPIRequestCombinedCompletionCallback combinedCompletion NS_SWIFT_NAME(completionCallback);

@property (nullable) RFAPIRequestCombinedCompletionCallback combinedComplation API_DEPRECATED_WITH_REPLACEMENT("combinedCompletion", macos(10.10, 10.10), ios(8.0, 8.0), tvos(9.0, 9.0)) NS_SWIFT_NAME(complationCallback);

/// For debugging purposes, delaying the sending of network requests.
/// This may be used to test whether the UI is in a proper state when network latency.
@property NSTimeInterval debugDelayRequestSend;

/// If no nil, simulate the request fail with the given error code.
@property NSInteger debugRequestFailWithCode;

/// This value will be passed to the task object.
@property (nullable) NSDictionary *userInfo;

@end

@interface RFAPIRequestConext (Swift)

/// Set callback to be executed when the request finishes successfully.
- (void)setSuccessCallback:(nullable void(^)(id<RFAPITask> __nonnull task, id __nullable responseObject))success NS_SWIFT_NAME(success(_:));

/// Set callback to be executed when the request finishes unsuccessfully.
- (void)setFailureCallback:(nullable void (^)(id<RFAPITask> __nullable task, NSError *__nonnull error))failure NS_SWIFT_NAME(failure(_:));

/// Set callback to be executed when the request is completed.
- (void)setFinishedCallback:(nullable void (^)(id<RFAPITask> __nullable task, BOOL success))finished NS_SWIFT_NAME(finished(_:));

/// Set callback to be executed when the request is completed.
- (void)setCompletionCallback:(nullable void (^)(id<RFAPITask> __nullable task, id __nullable responseObject, NSError *__nullable error))completion NS_SWIFT_NAME(completion(_:));

- (void)setComplationCallback:(nullable void (^)(id<RFAPITask> __nullable task, id __nullable responseObject, NSError *__nullable error))complation API_DEPRECATED_WITH_REPLACEMENT("-setCompletionCallback:", macos(10.10, 10.10), ios(8.0, 8.0), tvos(9.0, 9.0)) NS_SWIFT_NAME(complation(_:));

@end
