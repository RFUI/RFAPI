
#import "RFAPIPrivate.h"
#import "RFAPIDefineManager.h"
#import "RFAPIModelTransformer.h"
#import "RFAPISessionManager.h"
#import "RFAPISessionTask.h"
#import <RFMessageManager/RFMessageManager+RFDisplay.h>

NSErrorDomain const RFAPIErrorDomain = @"RFAPIErrorDomain";
NSString *const RFAPIRequestArrayParameterKey = @"_RFParmArray_";
NSString *const RFAPIRequestForceQuryStringParametersKey = @"_RFParmForceQuryString_";

// Avoid create many concurrent GCD queue.
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
        [op cancel];
    }
}

- (void)cancelOperationsWithGroupIdentifier:(nullable NSString *)identifier {
    for (id<RFAPITask>op in [self operationsWithGroupIdentifier:identifier]) {
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
    NSAssert(define, @"Can not find an API with name: %@.", APIName);
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
        NSAssert(identifier, @"Context identifier and define name both are nil.");
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
#if RFDEBUG
        NSString *debugFormat = [self.class localizedStringForKey:@"RFAPI.Debug.CannotCreateRequestError" value:@"Cannot create request: %@"];
        RFAPILogError_(debugFormat, e)
#endif
        NSError *error = [self.class localizedErrorWithDoomain:NSURLErrorDomain code:NSURLErrorCancelled underlyingError:e descriptionKey:@"RFAPI.Error.CannotCreateRequest" descriptionValue:@"Internal error, unable to create request" reasonKey:@"RFAPI.Error.CannotCreateRequestReason" reasonValue:@"It seems to be an application bug" suggestionKey:@"RFAPI.Error.CannotCreateRequestSuggestion" suggestionValue:@"Please try again. If it still doesn't work, try restarting the application" url:request.URL];
        [self _RFAPI_executeContext:context failure:error];
        return nil;
    }

    NSURLSessionDataTask *dataTask = [self.http.session dataTaskWithRequest:request];
    _RFAPISessionTask *task = [self.http addSessionTask:dataTask];
    task.manager = self;
    task.define = define;
    [self transferContext:context toTask:task];
    [task updateBindControlsEnabled:NO];

    // Start request
    RFNetworkActivityMessage *message = task.activityMessage;
    if (message) {
        dispatch_async_on_main(^{
            if (task.isEnd) return;
            [self.networkActivityIndicatorManager showMessage:message];
        });
    }

    if (context.debugRequestFailWithCode != 0) {
        NSError *error = [NSError errorWithDomain:RFAPIErrorDomain code:context.debugRequestFailWithCode userInfo:@{ NSLocalizedDescriptionKey: [NSString.alloc initWithFormat:@"Debug error, code: %@", @(context.debugRequestFailWithCode)] }];
        [self _RFAPI_executeTaskCallback:task failure:error];
        return task;
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
    task.uploadProgressBlock = context.uploadProgress;
    task.downloadProgressBlock = context.downloadProgress;
    task.bindControls = context.bindControls;
    task.success = context.success;
    task.failure = context.failure;
    task.complation = context.finished;
    task.combinedComplation = context.combinedComplation;
    task.responseObjectTransformer = context.responseObjectTransformer;
    task.debugDelayRequestSend = context.debugDelayRequestSend;
    task.userInfo = context.userInfo;
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
    if (context.timeoutInterval > 0) {
        mutableRequest.timeoutInterval = context.timeoutInterval;
    }

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
                if (!self.modelTransformer) {
                    NSLog(@"⚠️ Response except object, but modelTransformer has not been set.");
                    modelObject = responseObject;
                }
                if (error) {
                    [self _RFAPI_executeTaskCallback:task failure:error];
                }
                else {
                    if (task.responseObjectTransformer) {
                        modelObject = task.responseObjectTransformer(task.define, modelObject);
                    }
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
    task.isSuccess = YES;
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        [task updateBindControlsEnabled:YES];
        RFNetworkActivityMessage *message = task.activityMessage;
        if (message) {
            dispatch_sync_on_main(^{
                [self.networkActivityIndicatorManager hideMessage:message];
            });
        }

        RFAPIRequestSuccessCallback scb = task.success;
        if (scb) {
            task.success = nil;
            scb(task, responseObject);
        }
        task.failure = nil;
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
    task.isSuccess = NO;
    BOOL isCancel = (error.code == NSURLErrorCancelled && [error.domain isEqualToString:NSURLErrorDomain]);
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        [task updateBindControlsEnabled:YES];
        RFMessageManager *messageManager = self.networkActivityIndicatorManager;
        RFNetworkActivityMessage *message = task.activityMessage;
        if (message && messageManager) {
            dispatch_sync_on_main(^{
                [messageManager hideMessage:message];
            });
        }

        task.success = nil;
        if (!isCancel) {
            BOOL shouldContinueErrorHandling = [self generalHandlerForError:error withDefine:task.define task:task failureCallback:task.failure];
            if (shouldContinueErrorHandling) {
                RFAPIRequestFailureCallback fcb = task.failure;
                if (fcb) {
                    fcb(task, error);
                }
                else if (!task.combinedComplation) {
                    if (messageManager) {
                        dispatch_sync_on_main(^{
                            [messageManager alertError:error title:nil fallbackMessage:@"Request Failed"];
                        });
                    }
                }
            }
        }
        task.failure = nil;
        RFAPIRequestFinishedCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, NO);
        }
        RFAPIRequestCombinedCompletionCallback cbcb = task.combinedComplation;
        if (cbcb) {
            task.combinedComplation = nil;
            cbcb(task, nil, isCancel ? nil : error);
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

#pragma mark -

+ (NSError *)localizedErrorWithDoomain:(NSErrorDomain)domain code:(NSInteger)code underlyingError:(NSError *)error descriptionKey:(NSString *)descriptionKey descriptionValue:(NSString *)descriptionValue reasonKey:(NSString *)reasonKey reasonValue:(NSString *)reasonValue suggestionKey:(NSString *)suggestionKey suggestionValue:(NSString *)suggestionValue url:(NSURL *)url {
    NSMutableDictionary *eInfo = [NSMutableDictionary.alloc initWithCapacity:5];
    eInfo[NSLocalizedDescriptionKey] = [self localizedStringForKey:descriptionKey value:descriptionValue];
    if (reasonKey || reasonValue) {
        NSString *reason = [self localizedStringForKey:reasonKey value:reasonValue];
        if (reason.length) {
            eInfo[NSLocalizedFailureReasonErrorKey] = reason;
        }
    }
    if (suggestionKey || suggestionValue) {
        NSString *suggestion = [self localizedStringForKey:suggestionKey value:suggestionValue];
        if (suggestion.length) {
            eInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion;
        }
    }
    if (error) {
        eInfo[NSUnderlyingErrorKey] = error;
    }
    if (url) {
        eInfo[NSURLErrorKey] = url;
    }
    return [NSError errorWithDomain:domain code:code userInfo:eInfo];
}

+ (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSParameterAssert(key || value);
    return [NSBundle.mainBundle localizedStringForKey:key value:value table:nil];
}

@end


@implementation RFAPIRequestConext

@end

@implementation RFAPIRequestConext (Swift)

- (void)setSuccessCallback:(void (^)(id<RFAPITask> _Nonnull, id _Nullable))success {
    self.success = success;
}
- (void)setFailureCallback:(void (^)(id<RFAPITask> _Nullable, NSError * _Nonnull))failure {
    self.failure = failure;
}
- (void)setFinishedCallback:(void (^)(id<RFAPITask> _Nullable, BOOL))finished {
    self.finished = finished;
}
- (void)setComplationCallback:(void (^)(id<RFAPITask> _Nullable, id _Nullable, NSError * _Nullable))complation {
    self.combinedComplation = complation;
}

@end

