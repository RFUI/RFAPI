
#import "RFAPIPrivate.h"
#import "RFAPIDefineManager.h"
#import "RFAPIModelTransformer.h"
#import "RFAPISessionManager.h"
#import "RFAPISessionTask.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFURLRequestSerialization.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <RFMessageManager/RFMessageManager+RFDisplay.h>
#import <RFKit/NSFileManager+RFKit.h>

NSErrorDomain const RFAPIErrorDomain = @"RFAPIErrorDomain";
NSString *const RFAPIRequestArrayParameterKey = @"_RFArray_";
NSString *const RFAPIRequestForceQuryStringParametersKey = @"RFAPIRequestForceQuryStringParametersKey";

NSString *RFAPILocalizedString(NSString *key, NSString *value) {
    return [NSBundle.mainBundle localizedStringForKey:key value:value table:nil];
}

static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t af_url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_processing_queue = dispatch_queue_create("com.github.RFUI.RFAPI.session.processing", DISPATCH_QUEUE_CONCURRENT);
    });

    return af_url_session_manager_processing_queue;
}

static dispatch_group_t url_session_manager_completion_group() {
    static dispatch_group_t af_url_session_manager_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_completion_group = dispatch_group_create();
    });

    return af_url_session_manager_completion_group;
}

@implementation RFAPI
RFInitializingRootForNSObject

- (void)onInit {
}

- (void)afterInit {
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p, operations: %@>", self.class, (void *)self, self._RFAPI_sessionManager.allTasks];
}

- (_RFURLSessionManager *)http {
    _RFURLSessionManager *http = self._RFAPI_sessionManager;
    if (http) return http;
    NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
    http = [_RFURLSessionManager.alloc initWithSessionConfiguration:config];
    self._RFAPI_sessionManager = http;
    return http;
}
- (void)setHttp:(_RFURLSessionManager *)http {
    self._RFAPI_sessionManager = http;
}

#if !TARGET_OS_WATCH
- (AFNetworkReachabilityManager *)reachabilityManager {
    if (!_reachabilityManager) {
        _reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _reachabilityManager;
}
#endif

- (dispatch_queue_t)processingQueue {
    if (!_processingQueue) {
        _processingQueue = url_session_manager_processing_queue();
    }
    return _processingQueue;
}

- (dispatch_queue_t)completionQueue {
    if (!_completionQueue) {
        _completionQueue = dispatch_get_main_queue();
    }
    return _completionQueue;
}

- (dispatch_group_t)completionGroup {
    if (!_completionGroup) {
        _completionGroup = url_session_manager_completion_group();
    }
    return _completionGroup;
}

- (RFAPIDefineManager *)defineManager {
    if (!_defineManager) {
        _defineManager = [RFAPIDefineManager.alloc init];
    }
    return _defineManager;
}

#pragma mark - Request management

- (void)cancelOperationWithIdentifier:(nullable NSString *)identifier {
    for (id<RFAPITask>op in [self operationsWithIdentifier:identifier]) {
        _dout_debug(@"Cancel HTTP request operation(%p) with identifier: %@", (void *)op, identifier);
        [op cancel];
    }
}

- (void)cancelOperationsWithGroupIdentifier:(nullable NSString *)identifier {
    for (id<RFAPITask>op in [self operationsWithGroupIdentifier:identifier]) {
        _dout_debug(@"Cancel HTTP request operation(%p) with group identifier: %@", (void *)op, identifier);
        [op cancel];
    }
}

- (nonnull NSArray<id<RFAPITask>> *)operationsWithIdentifier:(nullable NSString *)identifier {
    @autoreleasepool {
        _RFURLSessionManager *http = self._RFAPI_sessionManager;
        if (!http) return @[];
        return [http.allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @keypathClassInstance(_RFAPISessionTask, identifier), identifier]];
    }
}

- (nonnull NSArray<id<RFAPITask>> *)operationsWithGroupIdentifier:(nullable NSString *)identifier {
    @autoreleasepool {
        _RFURLSessionManager *http = self._RFAPI_sessionManager;
        if (!http) return @[];
        return [http.allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@", @keypathClassInstance(_RFAPISessionTask, groupIdentifier), identifier]];
    }
}

#pragma mark - Request

- (id<RFAPITask>)requestWithName:(NSString *)APIName context:(NS_NOESCAPE void (^)(__kindof RFAPIRequestConext * _Nonnull))contextBlock {
    NSParameterAssert(APIName);
    RFAPIDefine *define = [self.defineManager defineForName:APIName];
    if (!define.name) {
        define.name = APIName;
    }
    RFAssert(define, @"Can not find an API with name: %@.", APIName)
    if (!define) return nil;
    return [self requestWithDefine:define context:contextBlock];
}

- (id<RFAPITask>)requestWithDefine:(RFAPIDefine *)APIDefine context:(NS_NOESCAPE void (^)(__kindof RFAPIRequestConext * _Nonnull))contextBlock {
    __kindof RFAPIRequestConext *context = [(self.requestConextClass?: RFAPIRequestConext.class) new];
    if (contextBlock) {
        contextBlock(context);
    }
    NSString *identifier = context.identifier;
    if (!identifier) {
        identifier = APIDefine.name;
        RFAssert(identifier, @"Context identifier and define name both are nil.")
        context.identifier = identifier;
    }
    if (!context.activityMessage && context.loadMessage) {
        RFNetworkActivityMessage *m = [[RFNetworkActivityMessage alloc] initWithIdentifier:identifier message:context.loadMessage status:RFNetworkActivityStatusLoading];
        m.modal = context.loadMessageShownModal;
        context.activityMessage = m;
    }
    // todo: merge default define

    NSError *e = nil;
    NSMutableURLRequest *request = [self URLRequestWithDefine:APIDefine context:context error:&e];
    if (!request) {
        RFAPILogError_(@"无法创建请求: %@", e)
        NSMutableDictionary *eInfo = [NSMutableDictionary.alloc initWithCapacity:4];
        eInfo[NSLocalizedDescriptionKey] = @"内部错误，无法创建请求";
        eInfo[NSLocalizedFailureReasonErrorKey] = @"很可能是应用 bug";
        eInfo[NSLocalizedRecoverySuggestionErrorKey] = @"请再试一次，如果依旧请尝试重启应用。给您带来不便，敬请谅解";
        if (e) {
            eInfo[NSUnderlyingErrorKey] = e;
        }
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:eInfo];
        [self _RFAPI_executeContext:context failure:error];
        return nil;
    }
    if (context.requestCustomization) {
        request = context.requestCustomization(request);
        NSAssert(request, @"requestCustomization must not return nil.");
    }

    NSURLSessionDataTask *dataTask = [self.http.session dataTaskWithRequest:request];
    _RFAPISessionTask *task = [self.http addSessionTask:dataTask];
    task.manager = self;
    task.define = APIDefine;
    [self transferContext:context toTask:task];

    // Start request
    RFNetworkActivityMessage *message = task.activityMessage;
    if (message) {
        dispatch_async_on_main(^{
            if (task.isEnd) return;
            [self.networkActivityIndicatorManager showMessage:message];
        });
    }
    dispatch_async(self.processingQueue, ^{
        if (task.isEnd) return;
        [dataTask resume];
    });
    return task;
}

- (void)transferContext:(RFAPIRequestConext *)context toTask:(_RFAPISessionTask *)task {
    task.identifier = context.identifier ?: task.define.name;
    task.groupIdentifier = context.groupIdentifier;
    task.activityMessage = context.activityMessage;
    task.uploadProgressBlock = context.downloadProgress;
    task.downloadProgressBlock = context.downloadProgress;
    task.success = context.success;
    task.failure = context.failure;
    task.complation = context.complation;
}

#pragma mark - Build Request

#define RFAPIMakeRequestError_(CONDITION)\
    if (CONDITION) {\
        if (error) {\
            *error = e;\
        }\
        return nil;\
    }

- (nullable NSMutableURLRequest *)URLRequestWithDefine:(RFAPIDefine *)define context:(RFAPIRequestConext *)context error:(NSError *_Nullable __autoreleasing *)error {
    NSParameterAssert(define);
    NSParameterAssert(context);
    NSParameterAssert(error);

    // Preprocessing arguments
    NSMutableDictionary *requestParameters = [NSMutableDictionary.alloc initWithCapacity:16];
    NSMutableDictionary *requestHeaders = [NSMutableDictionary.alloc initWithCapacity:4];
    [self preprocessingRequestParameters:&requestParameters HTTPHeaders:&requestHeaders withParameters:context.parameters define:define context:context];

    // Creat URL
    NSError __autoreleasing *e = nil;
    NSURL *url = [self.defineManager requestURLForDefine:define parameters:requestParameters error:&e];
    RFAPIMakeRequestError_(!url)

    // Creat URLRequest
    NSMutableURLRequest *r;
    AFHTTPRequestSerializer *s = [self.defineManager requestSerializerForDefine:define];
    if (context.formData) {
        NSString *urlString = url.absoluteString;
        r = [s multipartFormRequestWithMethod:define.method ?: @"POST" URLString:urlString parameters:requestParameters constructingBodyWithBlock:context.formData error:&e];
    }
    else {
        r = [NSMutableURLRequest.alloc initWithURL:url];
        [r setHTTPMethod:define.method ?: @"GET"];
        NSArray *arrayParameter = requestParameters[RFAPIRequestArrayParameterKey];
        r = [[s requestBySerializingRequest:r withParameters:arrayParameter?: requestParameters error:&e] mutableCopy];
    }
    RFAPIMakeRequestError_(!r)

    // Set header
    [requestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *__unused stop) {
        [r setValue:value forHTTPHeaderField:field];
    }];

    // Finalization
    r = [self finalizeSerializedRequest:r withDefine:define controlInfo:nil];
    return r;
}

- (void)preprocessingRequestParameters:(NSMutableDictionary *_Nullable *_Nonnull)requestParameters HTTPHeaders:(NSMutableDictionary *_Nullable *_Nonnull)requestHeaders withParameters:(nullable NSDictionary *)parameters define:(nonnull RFAPIDefine *)define context:(nonnull RFAPIRequestConext *)context {
    BOOL needsAuthorization = define.needsAuthorization;

    [*requestParameters addEntriesFromDictionary:define.defaultParameters];
    if (needsAuthorization) {
        [*requestParameters addEntriesFromDictionary:self.defineManager.authorizationParameters];
    }
    if (parameters) {
        [*requestParameters addEntriesFromDictionary:(NSDictionary *)parameters];
    }

    [*requestHeaders addEntriesFromDictionary:define.HTTPRequestHeaders];
    [*requestHeaders addEntriesFromDictionary:context.HTTPHeaders];
    if (needsAuthorization) {
        [*requestHeaders addEntriesFromDictionary:self.defineManager.authorizationHeader];
    }
}

- (NSMutableURLRequest *)finalizeSerializedRequest:(NSMutableURLRequest *)request withDefine:(RFAPIDefine *)define controlInfo:(id<RFAPITask>)controlInfo {
    return request;
}

#pragma mark - Handel Response

- (dispatch_queue_t)responseProcessingQueue {
    if (_responseProcessingQueue) return _responseProcessingQueue;
    _responseProcessingQueue = dispatch_get_main_queue();
    return _responseProcessingQueue;
}

- (void)_RFAPI_handleTaskComplete:(_RFAPISessionTask *)task response:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {
    dispatch_async(self.processingQueue, ^{
        if (error) {
            [self _RFAPI_executeTaskCallback:task failure:error];
            return;
        }

        if (task.downloadFileURL) {
            [self _RFAPI_executeTaskCallback:task success:task.downloadFileURL];
            return;
        }

        NSError *serializationError = nil;
        id responseObject = [self.http.responseSerializer responseObjectForResponse:response data:data error:&serializationError];
        if (serializationError) {
            [self _RFAPI_executeTaskCallback:task failure:serializationError];
            return;
        }

        if ((!responseObject || responseObject == NSNull.null)
            && task.define.responseAcceptNull) {
            [self _RFAPI_executeTaskCallback:task success:nil];
            return;
        }

        RFAPIDefineResponseExpectType type = task.define.responseExpectType;
        switch (type) {
            case RFAPIDefineResponseExpectDefault: {
                [self _RFAPI_executeTaskCallback:task success:responseObject];
                return;
            }
            case RFAPIDefineResponseExpectSuccess: {
                NSError *e = nil;
                if (![self isSuccessResponse:&responseObject error:&e]) {
                    [self _RFAPI_executeTaskCallback:task failure:e];
                }
                else {
                    [self _RFAPI_executeTaskCallback:task success:responseObject];
                }
                return;
            }
            case RFAPIDefineResponseExpectObject:
            case RFAPIDefineResponseExpectObjects: {
                NSError *error = nil;
                id modelObject = [self.modelTransformer transformResponse:(id)responseObject toType:type kind:task.define.responseClass error:&error];
                if (error) {
                    [self _RFAPI_executeTaskCallback:task failure:error];
                }
                else {
                    [self _RFAPI_executeTaskCallback:task success:modelObject];
                }
                return;
            }
            default:
                NSAssert(false, @"Unexcept response type: %d", type);
                return;
        }
    });
}

- (void)_RFAPI_executeTaskCallback:(nonnull _RFAPISessionTask *)task success:(nullable id)responseObject {
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        task.failure = nil;
        RFAPIRequestSuccessCallback scb = task.success;
        if (scb) {
            task.success = nil;
            scb(task, responseObject);
        }
        RFNetworkActivityMessage *message = task.activityMessage;
        dispatch_sync_on_main(^{
            [self.networkActivityIndicatorManager hideMessage:message];
        });
        RFAPIRequestCompletionCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, YES);
        }
    });
}

- (void)_RFAPI_executeTaskCallback:(nonnull _RFAPISessionTask *)task failure:(nonnull NSError *)error {
    BOOL shouldContinue = [self generalHandlerForError:error withDefine:task.define task:task failureCallback:task.failure];

    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        task.success = nil;

        if (shouldContinue) {
            BOOL isCancel = (error.code == NSURLErrorCancelled && [error.domain isEqualToString:NSURLErrorDomain]);

            RFAPIRequestFailureCallback fcb = task.failure;
            if (fcb) {
                if (!isCancel) {
                    fcb(task, error);
                }
            }
            else {
                dispatch_sync_on_main(^{
                    [self.networkActivityIndicatorManager alertError:error title:nil fallbackMessage:@"Request Failed"];
                });
            }
        }
        task.failure = nil;

        RFNetworkActivityMessage *message = task.activityMessage;
        dispatch_sync_on_main(^{
            [self.networkActivityIndicatorManager hideMessage:message];
        });
        RFAPIRequestCompletionCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, NO);
        }
    });
}

- (void)_RFAPI_executeContext:(nonnull RFAPIRequestConext *)context failure:(nonnull NSError *)error {
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        RFAPIRequestFailureCallback fcb = context.failure;
        if (fcb) {
            fcb(nil, error);
        }
        RFAPIRequestCompletionCallback ccb = context.complation;
        if (ccb) {
            ccb(nil, NO);
        }
    });
}

- (BOOL)generalHandlerForError:(NSError *)error withDefine:(RFAPIDefine *)define task:(id<RFAPITask>)task failureCallback:(RFAPIRequestFailureCallback)failure {
    return YES;
}

- (BOOL)isSuccessResponse:(id _Nullable __strong *_Nonnull)responseObjectRef error:(NSError *_Nullable __autoreleasing *_Nullable)error {
    return YES;
}

@end


@implementation RFAPIRequestConext

@end
