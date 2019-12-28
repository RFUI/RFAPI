
#import "RFAPISessionManager.h"
#import <objc/runtime.h>
#import "RFAPISessionTask.h"

@interface _RFURLSessionManager ()
@property NSOperationQueue *operationQueue;
@property NSURLSession *session;
@property NSMutableDictionary<NSNumber *, _RFAPISessionTask *> *mutableTaskDelegatesKeyedByTaskIdentifier;
@property NSString *taskDescriptionForSessionTasks;
@property NSLock *lock;
@end

@implementation _RFURLSessionManager

- (instancetype)init {
    return [self initWithSessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super init];
    if (!self) {
        return nil;
    }

    if (!configuration) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }

    self.operationQueue = [NSOperationQueue.alloc init];
    self.operationQueue.maxConcurrentOperationCount = 1;

    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.operationQueue];

    self.mutableTaskDelegatesKeyedByTaskIdentifier = [NSMutableDictionary.alloc initWithCapacity:8];

    self.lock = [NSLock.alloc init];
    self.lock.name = @"com.github.RFUI.RFAPI.session.manager.lock";
    self.taskDescriptionForSessionTasks = NSUUID.UUID.UUIDString;

    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * dataTasks, NSArray<NSURLSessionUploadTask *> * uploadTasks, NSArray<NSURLSessionDownloadTask *> * downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks) {
            [self addDelegateForDataTask:task uploadProgress:nil downloadProgress:nil completionHandler:nil];
        }

        for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
            [self addDelegateForUploadTask:uploadTask progress:nil completionHandler:nil];
        }

        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            [self addDelegateForDownloadTask:downloadTask progress:nil destination:nil completionHandler:nil];
        }
    }];

    return self;
}

#pragma mark Resettable propertys

- (id<AFURLRequestSerialization>)requestSerializer {
    if (!_requestSerializer) {
        _requestSerializer = [AFJSONRequestSerializer.alloc init];
    }
    return _requestSerializer;
}

- (id<AFURLResponseSerialization>)responseSerializer {
    if (!_responseSerializer) {
        _responseSerializer = [AFJSONResponseSerializer.alloc init];
    }
    return _responseSerializer;
}

- (AFSecurityPolicy *)securityPolicy {
    if (!_securityPolicy) {
        _securityPolicy = [AFSecurityPolicy defaultPolicy];
    }
    return _securityPolicy;
}

#if !TARGET_OS_WATCH
- (AFNetworkReachabilityManager *)reachabilityManager {
    if (!_reachabilityManager) {
        _reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _reachabilityManager;
}
#endif

#pragma mark Task Delegate

- (_RFAPISessionTask *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);

    _RFAPISessionTask *delegate = nil;
    [self.lock lock];
    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
    [self.lock unlock];

    return delegate;
}

- (void)setDelegate:(_RFAPISessionTask *)delegate forTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    NSParameterAssert(delegate);

    [self.lock lock];
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [self.lock unlock];
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);

    [self.lock lock];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}

- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    _RFAPISessionTask *delegate = [[_RFAPISessionTask alloc] initWithTask:dataTask];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;

    dataTask.taskDescription = self.taskDescriptionForSessionTasks;
    [self setDelegate:delegate forTask:dataTask];

    delegate.uploadProgressBlock = uploadProgressBlock;
    delegate.downloadProgressBlock = downloadProgressBlock;
}

- (void)addDelegateForUploadTask:(NSURLSessionUploadTask *)uploadTask progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    _RFAPISessionTask *delegate = [[_RFAPISessionTask alloc] initWithTask:uploadTask];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;

    uploadTask.taskDescription = self.taskDescriptionForSessionTasks;

    [self setDelegate:delegate forTask:uploadTask];

    delegate.uploadProgressBlock = uploadProgressBlock;
}

- (void)addDelegateForDownloadTask:(NSURLSessionDownloadTask *)downloadTask progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    _RFAPISessionTask *delegate = [[_RFAPISessionTask alloc] initWithTask:downloadTask];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;

    if (destination) {
        delegate.downloadTaskDidFinishDownloading = ^NSURL * (NSURLSession * __unused session, NSURLSessionDownloadTask *task, NSURL *location) {
            return destination(location, task.response);
        };
    }

    downloadTask.taskDescription = self.taskDescriptionForSessionTasks;

    [self setDelegate:delegate forTask:downloadTask];

    delegate.downloadProgressBlock = downloadProgressBlock;
}

#pragma mark Tasks

- (NSArray *)tasksForKeyPath:(NSString *)keyPath {
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(dataTasks))]) {
            tasks = dataTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadTasks))]) {
            tasks = uploadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(downloadTasks))]) {
            tasks = downloadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(tasks))]) {
            tasks = [@[dataTasks, uploadTasks, downloadTasks] valueForKeyPath:@"@unionOfArrays.self"];
        }

        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    return tasks;
}

- (NSArray *)tasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)dataTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)uploadTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)downloadTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

#pragma mark -

- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks {
    if (cancelPendingTasks) {
        [self.session invalidateAndCancel];
    } else {
        [self.session finishTasksAndInvalidate];
    }
}

#pragma mark Create Request

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler {

    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    [self addDelegateForDataTask:dataTask uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
    return dataTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromData:bodyData];
    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler {
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithStreamedRequest:request];
    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    return uploadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {

    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
    [self addDelegateForDownloadTask:downloadTask progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    return downloadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithResumeData:resumeData];
    [self addDelegateForDownloadTask:downloadTask progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    return downloadTask;
}

#pragma mark Progress

- (NSProgress *)uploadProgressForTask:(NSURLSessionTask *)task {
    return [[self delegateForTask:task] uploadProgress];
}

- (NSProgress *)downloadProgressForTask:(NSURLSessionTask *)task {
    return [[self delegateForTask:task] downloadProgress];
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass([self class]), (void *)self, self.session, self.operationQueue];
}

- (BOOL)respondsToSelector:(SEL)selector {
    if (selector == @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)) {
        return self.taskWillPerformHTTPRedirection != nil;
    } else if (selector == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
        return self.dataTaskDidReceiveResponse != nil;
    } else if (selector == @selector(URLSession:dataTask:willCacheResponse:completionHandler:)) {
        return self.dataTaskWillCacheResponse != nil;
    }
    return [[self class] instancesRespondToSelector:selector];
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    if (self.sessionDidBecomeInvalid) {
        self.sessionDidBecomeInvalid(session, error);
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;

    if (self.sessionDidReceiveAuthenticationChallenge) {
        disposition = self.sessionDidReceiveAuthenticationChallenge(session, challenge, &credential);
    }
    else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        if ([self.securityPolicy evaluateServerTrust:trust forDomain:challenge.protectionSpace.host]) {
            credential = [NSURLCredential credentialForTrust:trust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            }
        }
        else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    NSURLRequest *redirectRequest = request;

    if (self.taskWillPerformHTTPRedirection) {
        redirectRequest = self.taskWillPerformHTTPRedirection(session, task, response, request);
    }

    if (completionHandler) {
        completionHandler(redirectRequest);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;

    if (self.taskDidReceiveAuthenticationChallenge) {
        disposition = self.taskDidReceiveAuthenticationChallenge(session, task, challenge, &credential);
    }
    else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        if ([self.securityPolicy evaluateServerTrust:trust forDomain:challenge.protectionSpace.host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:trust];
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    NSInputStream *inputStream = nil;

    if (self.taskNeedNewBodyStream) {
        inputStream = self.taskNeedNewBodyStream(session, task);
    } else if ([task.originalRequest.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
        inputStream = [task.originalRequest.HTTPBodyStream copy];
    }

    if (completionHandler) {
        completionHandler(inputStream);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {

    int64_t totalUnitCount = totalBytesExpectedToSend;
    if (totalUnitCount == NSURLSessionTransferSizeUnknown) {
        NSString *contentLength = [task.originalRequest valueForHTTPHeaderField:@"Content-Length"];
        if (contentLength) {
            totalUnitCount = (int64_t) [contentLength longLongValue];
        }
    }

    _RFAPISessionTask *delegate = [self delegateForTask:task];
    [delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];

    if (self.taskDidSendBodyData) {
        self.taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalUnitCount);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    _RFAPISessionTask *delegate = [self delegateForTask:task];

    // delegate may be nil when completing a task in the background
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];

        [self removeDelegateForTask:task];
    }

    if (self.taskDidComplete) {
        self.taskDidComplete(session, task, error);
    }
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;

    if (self.dataTaskDidReceiveResponse) {
        disposition = self.dataTaskDidReceiveResponse(session, dataTask, response);
    }

    if (completionHandler) {
        completionHandler(disposition);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    _RFAPISessionTask *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [self removeDelegateForTask:dataTask];
        [self setDelegate:delegate forTask:downloadTask];
    }

    if (self.dataTaskDidBecomeDownloadTask) {
        self.dataTaskDidBecomeDownloadTask(session, dataTask, downloadTask);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {

    _RFAPISessionTask *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];

    if (self.dataTaskDidReceiveData) {
        self.dataTaskDidReceiveData(session, dataTask, data);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    NSCachedURLResponse *cachedResponse = proposedResponse;

    if (self.dataTaskWillCacheResponse) {
        cachedResponse = self.dataTaskWillCacheResponse(session, dataTask, proposedResponse);
    }

    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}

#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    _RFAPISessionTask *delegate = [self delegateForTask:downloadTask];
    if (self.downloadTaskDidFinishDownloading) {
        NSURL *fileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (fileURL) {
            delegate.downloadFileURL = fileURL;
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error];
            return;
        }
    }
    [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    _RFAPISessionTask *delegate = [self delegateForTask:downloadTask];
    [delegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    if (self.downloadTaskDidWriteData) {
        self.downloadTaskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {

    _RFAPISessionTask *delegate = [self delegateForTask:downloadTask];
    [delegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
    if (self.downloadTaskDidResume) {
         self.downloadTaskDidResume(session, downloadTask, fileOffset, expectedTotalBytes);
     }
}

@end
