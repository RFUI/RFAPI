
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

RFDefineConstString(RFAPIErrorDomain);
static NSString *RFAPIOperationUIkControl = @"RFAPIOperationUIkControl";
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
        return [http.allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K.%K == %@", @keypathClassInstance(_RFAPISessionTask, control), @keypathClassInstance(RFAPIControl, identifier), identifier]];
    }
}

- (nonnull NSArray<id<RFAPITask>> *)operationsWithGroupIdentifier:(nullable NSString *)identifier {
    @autoreleasepool {
        _RFURLSessionManager *http = self._RFAPI_sessionManager;
        if (!http) return @[];
        return [http.allTasks filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K.%K == %@", @keypathClassInstance(_RFAPISessionTask, control), @keypathClassInstance(RFAPIControl, groupIdentifier), identifier]];
    }
}

#pragma mark - Request

#define RFAPICompletionCallback_(BLOCK, ...)\
    if (BLOCK) {\
        BLOCK(__VA_ARGS__);\
    }

- (nullable id<RFAPITask>)requestWithName:(nonnull NSString *)APIName parameters:(NSDictionary *)parameters formData:(nullable NSArray<RFHTTPRequestFormData *> *)arrayContainsFormDataObj controlInfo:(nullable RFAPIControl *)controlInfo uploadProgress:(void (^_Nullable)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress success:(void (^_Nullable )(id<RFAPITask>_Nullable operation, id _Nullable responseObject))success failure:(void (^_Nullable)(id<RFAPITask>_Nullable operation, NSError *_Nonnull error))failure completion:(void (^_Nullable)(id<RFAPITask>_Nullable operation))completion {
    NSParameterAssert(APIName);
    RFAPIDefine *define = [self.defineManager defineForName:APIName];
    RFAssert(define, @"Can not find an API with name: %@.", APIName)
    if (!define) return nil;

    NSError __autoreleasing *e = nil;
    NSMutableURLRequest *request = [self URLRequestWithDefine:define parameters:parameters formData:arrayContainsFormDataObj controlInfo:controlInfo error:&e];
    if (!request) {
        RFAPILogError_(@"无法创建请求: %@", e)
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{
            NSLocalizedDescriptionKey : @"内部错误，无法创建请求",
            NSLocalizedFailureReasonErrorKey : @"很可能是应用 bug",
            NSLocalizedRecoverySuggestionErrorKey : @"请再试一次，如果依旧请尝试重启应用。给您带来不便，敬请谅解"
        }];

        RFAPICompletionCallback_(failure, nil, error)
        RFAPICompletionCallback_(completion, nil)
        return nil;
    }

    // Request object get ready.
    // Build operation block.
    RFNetworkActivityMessage *message = controlInfo.message;
    void (^operationCompletion)(id) = ^(id<RFAPITask>blockOp) {
        dispatch_async_on_main(^{
            NSString *mid = message.identifier;
            if (mid) {
                [self.networkActivityIndicatorManager hideMessage:message];
            }

            if (completion) {
                completion(blockOp);
            }
        });
    };

    void (^operationSuccess)(id, id) = ^(id<RFAPITask>blockOp, id blockResponse) {
        dispatch_async_on_main(^{
            if (success) {
                success(blockOp, blockResponse);
            }
            operationCompletion(blockOp);
        });
    };

    void (^operationFailure)(id, NSError*) = ^(id<RFAPITask>blockOp, NSError *blockError) {
        dispatch_async_on_main(^{
            if (blockError.code == NSURLErrorCancelled && blockError.domain == NSURLErrorDomain) {
                dout_info(@"A HTTP operation cancelled: %@", blockOp)
                operationCompletion(blockOp);
                return;
            }

            if ([self generalHandlerForError:blockError withDefine:define controlInfo:controlInfo requestOperation:blockOp operationFailureCallback:failure]) {
                if (failure) {
                    failure(blockOp, blockError);
                }
                else {
                    [self.networkActivityIndicatorManager alertError:blockError title:nil fallbackMessage:@"Request Failed"];
                }
            }
            operationCompletion(blockOp);
        });
    };

    // Setup HTTP operation
    NSURLSessionDataTask *dataTask = [self.http.session dataTaskWithRequest:request];
    _RFAPISessionTask *task = [self.http addSessionTask:dataTask];
    task.manager = self;
    task.define = define;
    task.control = controlInfo;
    task.success = operationSuccess;
    task.failure = operationFailure;

    @weakify(task)
    task.completionHandler = ^(NSURLResponse * _Nullable response, id  _Nullable responseObject, NSError * _Nullable error) {
        @strongify(task)
        if (error) {
            operationFailure(dataTask, error);
            return;
        }
        @autoreleasepool {
            // todo: responseProcessingQueue
            // todo: control info
            //            dout_debug(@"HTTP request operation(%p) with info: %@ completed.", (void *)dataTask, [op valueForKeyPath:@"userInfo.RFAPIOperationUIkControl"])

            [self processingCompletionWithHTTPOperation:task responseObject:responseObject define:define control:nil success:operationSuccess failure:operationFailure];
        }
    };

    // Start request
    if (message) {
        dispatch_sync_on_main(^{
            [self.networkActivityIndicatorManager showMessage:message];
        });
    }
    dispatch_async(self.processingQueue, ^{
        if (task.isEnd) return;
        [dataTask resume];
    });
    return task;
}

- (id<RFAPITask>)requestWithName:(nonnull NSString *)APIName parameters:(NSDictionary *)parameters controlInfo:(RFAPIControl *)controlInfo success:(void (^)(id<RFAPITask>, id))success failure:(void (^)(id<RFAPITask>, NSError *))failure completion:(void (^)(id<RFAPITask>))completion {
    return [self requestWithName:APIName parameters:parameters formData:nil controlInfo:controlInfo uploadProgress:nil success:success failure:failure completion:completion];
}

#pragma mark - Build Request

#define RFAPIMakeRequestError_(CONDITION)\
    if (CONDITION) {\
        if (error) {\
            *error = e;\
        }\
        return nil;\
    }

- (nullable NSMutableURLRequest *)URLRequestWithDefine:(nonnull RFAPIDefine *)define parameters:(nullable NSDictionary *)parameters formData:(nullable NSArray *)RFFormData controlInfo:(nullable RFAPIControl *)controlInfo error:(NSError *_Nullable __autoreleasing *_Nullable)error {
    NSParameterAssert(define);

    // Preprocessing arguments
    NSMutableDictionary *requestParameters = [NSMutableDictionary.alloc initWithCapacity:16];
    NSMutableDictionary *requestHeaders = [NSMutableDictionary.alloc initWithCapacity:4];
    [self preprocessingRequestParameters:&requestParameters HTTPHeaders:&requestHeaders withParameters:(NSDictionary *)parameters define:define controlInfo:controlInfo];

    // Creat URL
    NSError __autoreleasing *e = nil;
    NSURL *url = [self.defineManager requestURLForDefine:define parameters:requestParameters error:&e];
    RFAPIMakeRequestError_(!url)

    // Creat URLRequest
    NSMutableURLRequest *r;
    AFHTTPRequestSerializer *s = [self.defineManager requestSerializerForDefine:define];
    if (RFFormData.count) {
        NSString *urlString = url.absoluteString;
        r = [s multipartFormRequestWithMethod:define.method ?: @"GET" URLString:urlString parameters:requestParameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            for (RFHTTPRequestFormData *file in RFFormData) {
                NSError __autoreleasing *f_e = nil;
                [file buildFormData:formData error:&f_e];
                if (f_e) dout_error(@"%@", f_e)
            }
        } error:&e];
    }
    else {
        r = [NSMutableURLRequest.alloc initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:40];
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
    r = [self finalizeSerializedRequest:r withDefine:define controlInfo:controlInfo];
    return r;
}

- (void)preprocessingRequestParameters:(NSMutableDictionary *_Nullable *_Nonnull)requestParameters HTTPHeaders:(NSMutableDictionary *_Nullable *_Nonnull)requestHeaders withParameters:(nullable NSDictionary *)parameters define:(nonnull RFAPIDefine *)define controlInfo:(nullable RFAPIControl *)controlInfo {
    BOOL needsAuthorization = define.needsAuthorization;

    [*requestParameters addEntriesFromDictionary:define.defaultParameters];
    if (needsAuthorization) {
        [*requestParameters addEntriesFromDictionary:self.defineManager.authorizationParameters];
    }
    if (parameters) {
        [*requestParameters addEntriesFromDictionary:(NSDictionary *)parameters];
    }

    [*requestHeaders addEntriesFromDictionary:define.HTTPRequestHeaders];
    if (needsAuthorization) {
        [*requestHeaders addEntriesFromDictionary:self.defineManager.authorizationHeader];
    }
}

- (nullable NSMutableURLRequest *)finalizeSerializedRequest:(nonnull NSMutableURLRequest *)request withDefine:(nonnull RFAPIDefine *)define controlInfo:(nullable RFAPIControl *)controlInfo {
    if (controlInfo.requestCustomization) {
        return controlInfo.requestCustomization(request);
    }
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
        RFAPIRequestCompletionCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, NO);
        }
    });
}

- (void)_RFAPI_executeTaskCallback:(nonnull _RFAPISessionTask *)task failure:(nonnull NSError *)error {
    dispatch_group_async(self.completionGroup, self.completionQueue, ^{
        task.success = nil;
        RFAPIRequestFailureCallback fcb = task.failure;
        if (fcb) {
            task.failure = nil;
            fcb(task, error);
        }
        RFAPIRequestCompletionCallback ccb = task.complation;
        if (ccb) {
            task.complation = nil;
            ccb(task, NO);
        }
    });
}

- (void)processingCompletionWithHTTPOperation:(nullable id<RFAPITask>)op responseObject:(nullable id)responseObject define:(nonnull RFAPIDefine *)define control:(nullable RFAPIControl *)control success:(void (^_Nonnull)(id _Nullable, id _Nullable))operationSuccess failure:(void (^_Nonnull)(id _Nullable, NSError *_Nonnull))operationFailure {

    if ((!responseObject || responseObject == NSNull.null)
        && define.responseAcceptNull) {
        operationSuccess(op, nil);
        return;
    }

    RFAPIDefineResponseExpectType type = define.responseExpectType;
    switch (type) {
        case RFAPIDefineResponseExpectDefault: {
            operationSuccess(op, responseObject);
            return;
        }
        case RFAPIDefineResponseExpectSuccess: {
            NSError *error = nil;
            if (![self isSuccessResponse:&responseObject error:&error]) {
                operationFailure(op, error);
            }
            else {
                operationSuccess(op, responseObject);
            }
            return;
        }
        case RFAPIDefineResponseExpectObject:
        case RFAPIDefineResponseExpectObjects: {
            NSError *error = nil;
            id modelObject = [self.modelTransformer transformResponse:(id)responseObject toType:type kind:define.responseClass error:&error];
            if (error) {
                operationFailure(op, error);
            }
            else {
                operationSuccess(op, modelObject);
            }
            return;
        }
        default:
            NSAssert(false, @"Unexcept response type: %d", type);
            return;
    }
}

- (BOOL)generalHandlerForError:(nonnull NSError *)error withDefine:(nonnull RFAPIDefine *)define controlInfo:(nullable RFAPIControl *)controlInfo requestOperation:(nullable id<RFAPITask>)operation operationFailureCallback:(void (^_Nullable)(id<RFAPITask> _Nullable, NSError *_Nonnull))operationFailureCallback {
    return YES;
}

- (BOOL)isSuccessResponse:(id _Nullable __strong *_Nonnull)responseObjectRef error:(NSError *_Nullable __autoreleasing *_Nullable)error {
    return YES;
}

@end


#pragma mark - RFAPIControl
NSString *const RFAPIMessageControlKey = @"_RFAPIMessageControl";
NSString *const RFAPIIdentifierControlKey = @"_RFAPIIdentifierControl";
NSString *const RFAPIGroupIdentifierControlKey = @"_RFAPIGroupIdentifierControl";
NSString *const RFAPIBackgroundTaskControlKey = @"_RFAPIBackgroundTaskControl";
NSString *const RFAPIRequestCustomizationControlKey = @"_RFAPIRequestCustomizationControl";

@implementation RFAPIControl

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, identifier = %@, groupIdentifier = %@>", self.class, (void *)self, self.identifier, self.groupIdentifier];
}

- (nonnull id)initWithDictionary:(nonnull NSDictionary *)info {
    self = [super init];
    if (self) {
        _message = info[RFAPIMessageControlKey];
        _identifier = info[RFAPIIdentifierControlKey];
        _groupIdentifier = info[RFAPIGroupIdentifierControlKey];
        _backgroundTask = [info[RFAPIBackgroundTaskControlKey] boolValue];
        _requestCustomization = info[RFAPIRequestCustomizationControlKey];
    }
    return self;
}

- (nonnull id)initWithIdentifier:(nonnull NSString *)identifier loadingMessage:(nullable NSString *)message {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _message = [[RFNetworkActivityMessage alloc] initWithIdentifier:identifier message:message status:RFNetworkActivityStatusLoading];
    }
    return self;
}

@end

#pragma mark - RFHTTPRequestFormData

typedef NS_ENUM(short, RFHTTPRequestFormDataSourceType) {
    RFHTTPRequestFormDataSourceTypeURL = 0,
    RFHTTPRequestFormDataSourceTypeStream,
    RFHTTPRequestFormDataSourceTypeData
};

@interface RFHTTPRequestFormData ()
@property RFHTTPRequestFormDataSourceType type;
@end

@implementation RFHTTPRequestFormData

+ (nonnull instancetype)formDataWithFileURL:(nonnull NSURL *)fileURL name:(nonnull NSString *)name {
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    RFHTTPRequestFormData *this = [RFHTTPRequestFormData new];
    this.fileURL = fileURL;
    this.name = name;
    this.type = RFHTTPRequestFormDataSourceTypeURL;
    return this;
}

+ (nonnull instancetype)formDataWithData:(nonnull NSData *)data name:(nonnull NSString *)name {
    NSParameterAssert(data);
    NSParameterAssert(name);
    RFHTTPRequestFormData *this = [RFHTTPRequestFormData new];
    this.data = data;
    this.name = name;
    this.type = RFHTTPRequestFormDataSourceTypeData;
    return this;
}

+ (nonnull instancetype)formDataWithData:(nonnull NSData *)data name:(nonnull NSString *)name fileName:(nullable NSString *)fileName mimeType:(nullable NSString *)mimeType {
    NSParameterAssert(data);
    NSParameterAssert(name);
    RFHTTPRequestFormData *this = [RFHTTPRequestFormData new];
    this.data = data;
    this.name = name;
    this.fileName = fileName;
    this.mimeType = mimeType;
    this.type = RFHTTPRequestFormDataSourceTypeData;
    return this;
}

- (void)buildFormData:(nonnull id<AFMultipartFormData>)formData error:(NSError *_Nullable __autoreleasing *_Nullable)error {
    switch (self.type) {
        case RFHTTPRequestFormDataSourceTypeURL: {
            NSURL *fileURL = self.fileURL;
            [formData appendPartWithFileURL:fileURL name:self.name error:error];
            break;
        }
        case RFHTTPRequestFormDataSourceTypeData: {
            NSData *data = self.data;
            if (self.fileName
                && self.mimeType) {
                [formData appendPartWithFileData:data name:self.name fileName:(NSString *)self.fileName mimeType:(NSString *)self.mimeType];
            }
            else {
                [formData appendPartWithFormData:data name:self.name];
            }
            break;
        }
        case RFHTTPRequestFormDataSourceTypeStream:
            // todo
        default:
            break;
    }
}

@end
