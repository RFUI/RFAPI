
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

NSErrorDomain const RFAPIErrorDomain = @"RFAPIErrorDomain";
NSString *const RFAPIRequestArrayParameterKey = @"_RFParmArray_";
NSString *const RFAPIRequestForceQuryStringParametersKey = @"_RFParmForceQuryString_";

NSString *RFAPILocalizedString(NSString *key, NSString *value) {
    return [NSBundle.mainBundle localizedStringForKey:key value:value table:nil];
}

static dispatch_queue_t api_default_processing_queue() {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.github.RFUI.RFAPI.session.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

static dispatch_group_t api_default_completion_group() {
    static dispatch_group_t group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        group = dispatch_group_create();
    });
    return group;
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

- (NSURLSessionConfiguration *)sessionConfiguration {
    return self._RFAPI_sessionManager.session.configuration ?: _sessionConfiguration;
}

- (_RFURLSessionManager *)http {
    _RFURLSessionManager *http = self._RFAPI_sessionManager;
    if (http) return http;
    NSURLSessionConfiguration *config = self.sessionConfiguration ?: NSURLSessionConfiguration.defaultSessionConfiguration;
    http = [_RFURLSessionManager.alloc initWithSessionConfiguration:config];
    http.master = self;
    self._RFAPI_sessionManager = http;
    return http;
}

#if !TARGET_OS_WATCH
- (AFNetworkReachabilityManager *)reachabilityManager {
    if (!_reachabilityManager) {
        NSString *host = self.baseURL.host;
        _reachabilityManager = (host.length) ? [AFNetworkReachabilityManager managerForDomain:host] : [AFNetworkReachabilityManager sharedManager];
    }
    return _reachabilityManager;
}
#endif

- (dispatch_queue_t)processingQueue {
    if (!_processingQueue) {
        _processingQueue = api_default_processing_queue();
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
        _completionGroup = api_default_completion_group();
    }
    return _completionGroup;
}

- (RFAPIDefineManager *)defineManager {
    if (!_defineManager) {
        _defineManager = [RFAPIDefineManager.alloc init];
    }
    return _defineManager;
}

- (AFSecurityPolicy *)securityPolicy {
    if (!_securityPolicy) {
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    return _securityPolicy;
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

    RFAPIDefine *defaultDefine = self.defineManager.defaultDefine;
    RFAPIDefine *define = defaultDefine ? [APIDefine newDefineMergedDefault:defaultDefine] : APIDefine;
    if (!define.baseURL && self.baseURL) {
        define.baseURL = self.baseURL;
    }

    NSError *e = nil;
    NSMutableURLRequest *request = [self _RFAPI_makeURLRequestWithDefine:define context:context error:&e];
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

    NSURLSessionDataTask *dataTask = [self.http.session dataTaskWithRequest:request];
    _RFAPISessionTask *task = [self.http addSessionTask:dataTask];
    task.manager = self;
    task.define = define;
    [self transferContext:context toTask:task];

    // Start request
    RFNetworkActivityMessage *message = task.activityMessage;
    if (message) {
        dispatch_async_on_main(^{
            if (task.isEnd) return;
            [self.networkActivityIndicatorManager showMessage:message];
        });
    }
    dispatch_block_t work = ^{
        if (task.isEnd) return;
        [dataTask resume];
    };
    if (task.debugDelayRequestSend > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(task.debugDelayRequestSend * NSEC_PER_SEC)), self.processingQueue, work);
    }
    else {
        dispatch_async(self.processingQueue, work);
    }
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
    task.complation = context.finished;
    task.combinedComplation = context.combinedComplation;
    task.userInfo = context.userInfo;
    task.debugDelayRequestSend = context.debugDelayRequestSend;
}

#pragma mark - Build Request

- (nullable NSMutableURLRequest *)_RFAPI_makeURLRequestWithDefine:(RFAPIDefine *)define context:(RFAPIRequestConext *)context error:(NSError *_Nullable __autoreleasing *)error {
    NSParameterAssert(define);
    NSParameterAssert(context);
    NSParameterAssert(error);

    // Preprocessing arguments
    NSMutableDictionary *parameters = [NSMutableDictionary.alloc initWithCapacity:16];
    NSMutableDictionary *headers = [NSMutableDictionary.alloc initWithCapacity:4];
    [self preprocessingRequestParameters:&parameters HTTPHeaders:&headers withParameters:context.parameters define:define context:context];

    // Creat URL
    NSURL *url = [self.defineManager requestURLForDefine:define parameters:parameters error:error];
    if (!url) return nil;

    // Creat URLRequest
    NSMutableURLRequest *mutableRequest = nil;

    id<AFURLRequestSerialization> serializer = [self.defineManager requestSerializerForDefine:define];
    if (context.formData) {
        NSAssert([serializer respondsToSelector:@selector(multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:error:)], @"For a request needs post form data, the serializer should be an AFHTTPRequestSerializer or response to multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:error:.");
        NSString *urlString = url.absoluteString;
        AFHTTPRequestSerializer *hs = serializer;
        mutableRequest = [hs multipartFormRequestWithMethod:define.method ?: @"POST" URLString:urlString parameters:parameters constructingBodyWithBlock:context.formData error:error];
    }
    else {
        mutableRequest = [NSMutableURLRequest.alloc initWithURL:url];
        [mutableRequest setHTTPMethod:define.method ?: @"GET"];
        NSArray *arrayParameter = parameters[RFAPIRequestArrayParameterKey];
        mutableRequest = [[serializer requestBySerializingRequest:mutableRequest withParameters:arrayParameter?: parameters error:error] mutableCopy];
    }
    if (!mutableRequest) return nil;

    // Set header
    [headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *_) {
        [mutableRequest setValue:value forHTTPHeaderField:field];
    }];

    // Finalization
    mutableRequest = [self finalizeSerializedRequest:mutableRequest withDefine:define context:context];
    return mutableRequest;
}

- (void)preprocessingRequestParameters:(NSMutableDictionary * _Nullable __strong *)requestParameters HTTPHeaders:(NSMutableDictionary * _Nullable __strong *)requestHeaders withParameters:(NSDictionary *)parameters define:(RFAPIDefine *)define context:(RFAPIRequestConext *)context {
    BOOL needsAuthorization = define.needsAuthorization;
    NSDictionary *entries = nil;
    if ((entries = define.defaultParameters)) {
        [*requestParameters addEntriesFromDictionary:entries];
    }
    if (needsAuthorization) {
        if ((entries = self.defineManager.authorizationParameters)) {
            [*requestParameters addEntriesFromDictionary:entries];
        }
    }
    if ((entries = parameters)) {
        [*requestParameters addEntriesFromDictionary:entries];
    }

    if ((entries = define.HTTPRequestHeaders)) {
        [*requestHeaders addEntriesFromDictionary:entries];
    }
    if (needsAuthorization) {
        if ((entries = self.defineManager.authorizationHeader)) {
            [*requestHeaders addEntriesFromDictionary:entries];
        }
    }
    if ((entries = context.HTTPHeaders)) {
        [*requestHeaders addEntriesFromDictionary:entries];
    }
}

- (NSMutableURLRequest *)finalizeSerializedRequest:(NSMutableURLRequest *)request withDefine:(RFAPIDefine *)define context:(nonnull RFAPIRequestConext *)context {
    if (context.requestCustomization) {
        request = context.requestCustomization(request);
        NSAssert(request, @"requestCustomization must not return nil.");
    }
    return request;
}

#pragma mark - Handel Response

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
        id<AFURLResponseSerialization> serializer = [self.defineManager responseSerializerForDefine:task.define];
        id responseObject = [serializer responseObjectForResponse:response data:data error:&serializationError];
        task.responseObject = responseObject;
        if (serializationError) {
            [self _RFAPI_executeTaskCallback:task failure:serializationError];
            return;
        }

        if ((!responseObject || responseObject == NSNull.null)
            && task.define.responseAcceptNull) {
            [self _RFAPI_executeTaskCallback:task success:responseObject];
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
    task.responseObject = responseObject;
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        task.failure = nil;
        RFAPIRequestSuccessCallback scb = task.success;
        if (scb) {
            task.success = nil;
            scb(task, responseObject);
        }
        RFNetworkActivityMessage *message = task.activityMessage;
        if (message) {
            dispatch_sync_on_main(^{
                [self.networkActivityIndicatorManager hideMessage:message];
            });
        }
        RFAPIRequestFinishedCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, YES);
        }
        RFAPIRequestCombinedCompletionCallback cbcb = task.combinedComplation;
        if (cbcb) {
            task.combinedComplation = nil;
            cbcb(task, responseObject, nil);
        }
    });
}

- (void)_RFAPI_executeTaskCallback:(nonnull _RFAPISessionTask *)task failure:(nonnull NSError *)error {
    task.error = error;
    BOOL shouldContinue = [self generalHandlerForError:error withDefine:task.define task:task failureCallback:task.failure];

    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        task.success = nil;
        RFMessageManager *messageManager = self.networkActivityIndicatorManager;
        if (shouldContinue) {
            BOOL isCancel = (error.code == NSURLErrorCancelled && [error.domain isEqualToString:NSURLErrorDomain]);

            RFAPIRequestFailureCallback fcb = task.failure;
            if (fcb) {
                if (!isCancel) {
                    fcb(task, error);
                }
            }
            else {
                if (messageManager) {
                    dispatch_sync_on_main(^{
                        [messageManager alertError:error title:nil fallbackMessage:@"Request Failed"];
                    });
                }
            }
        }
        task.failure = nil;

        RFNetworkActivityMessage *message = task.activityMessage;
        if (message && messageManager) {
            dispatch_sync_on_main(^{
                [messageManager hideMessage:message];
            });
        }
        RFAPIRequestFinishedCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, NO);
        }
        RFAPIRequestCombinedCompletionCallback cbcb = task.combinedComplation;
        if (cbcb) {
            task.combinedComplation = nil;
            cbcb(task, nil, error);
        }
    });
}

- (void)_RFAPI_executeContext:(nonnull RFAPIRequestConext *)context failure:(nonnull NSError *)error {
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        RFAPIRequestFailureCallback fcb = context.failure;
        if (fcb) {
            fcb(nil, error);
        }

        RFAPIRequestFinishedCallback ccb = context.finished;
        if (ccb) {
            ccb(nil, NO);
        }
        RFAPIRequestCombinedCompletionCallback cbcb = context.combinedComplation;
        if (cbcb) {
            cbcb(nil, nil, error);
        }
    });
}

- (BOOL)generalHandlerForError:(NSError *)error withDefine:(RFAPIDefine *)define task:(id<RFAPITask>)task failureCallback:(RFAPIRequestFailureCallback)failure {
    return YES;
}

- (BOOL)isSuccessResponse:(id  _Nullable __strong *)responseObjectRef error:(NSError * _Nullable __autoreleasing *)error {
    return YES;
}

@end


@implementation RFAPIRequestConext

@end

@implementation RFAPIRequestConext (Swift)

- (void)addSuccess:(void (^)(id<RFAPITask> _Nonnull, id _Nullable))success {
    self.success = success;
}
- (void)addFailure:(void (^)(id<RFAPITask> _Nullable, NSError * _Nonnull))failure {
    self.failure = failure;
}
- (void)addFinished:(void (^)(id<RFAPITask> _Nullable, BOOL))finished {
    self.finished = finished;
}
- (void)addComplation:(void (^)(id<RFAPITask> _Nullable, id _Nullable, NSError * _Nullable))complation {
    self.combinedComplation = complation;
}

@end

