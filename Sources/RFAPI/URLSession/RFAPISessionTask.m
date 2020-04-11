
#import "RFAPISessionTask.h"
#import "RFAPISessionManager.h"

@interface _RFAPISessionTask ()
@property NSMutableData *mutableData;
@end

@implementation _RFAPISessionTask

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableData = [NSMutableData.alloc initWithCapacity:512];
        _uploadProgress = [NSProgress.alloc initWithParent:nil userInfo:nil];
        _downloadProgress = [NSProgress.alloc initWithParent:nil userInfo:nil];

        for (NSProgress *progress in @[ _uploadProgress, _downloadProgress ]) {
            progress.totalUnitCount = NSURLSessionTransferSizeUnknown;
            [progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    return self;
}

- (void)dealloc {
    [self.downloadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    [self.uploadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

- (void)updateBindControlsEnabled:(BOOL)enabled {
    if (!self.bindControls.count) return;
    @weakify(self)
    dispatch_block_t work = ^{
        @strongify(self)
        if (!self) return;
        NSArray *controls = self.bindControls.copy;
        for (id anyControl in controls) {
#if TARGET_OS_OSX
            if ([(NSObject *)anyControl respondsToSelector:@selector(setEnabled:)]) {
                [(NSControl *)anyControl setEnabled:enabled];
            }
#else
            if ([(NSObject *)anyControl isKindOfClass:UIActivityIndicatorView.class]) {
                if (enabled) [(UIActivityIndicatorView *)anyControl stopAnimating];
                else [(UIActivityIndicatorView *)anyControl startAnimating];
            }
            else if ([(NSObject *)anyControl isKindOfClass:UIRefreshControl.class]) {
                if (enabled) [(UIRefreshControl *)anyControl endRefreshing];
                else [(UIRefreshControl *)anyControl beginRefreshing];
            }
            else if ([(NSObject *)anyControl respondsToSelector:@selector(setEnabled:)]) {
                [(UIControl *)anyControl setEnabled:enabled];
            }
#endif
        }
        if (enabled) {
            self.bindControls = nil;
        }
    };
    if (NSThread.isMainThread) {
        work();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), work);
    }
}

#pragma mark -

- (NSURLRequest *)currentRequest {
    return self.task.currentRequest;
}

- (NSURLRequest *)originalRequest {
    return self.task.originalRequest;
}

- (NSURLResponse *)response {
    return self.task.response;
}

#pragma mark -

- (BOOL)isEnd {
    switch (self.task.state) {
        case NSURLSessionTaskStateRunning:
        case NSURLSessionTaskStateSuspended:
            return NO;
        case NSURLSessionTaskStateCanceling:
        case NSURLSessionTaskStateCompleted:
            return YES;
    }
}

- (void)suspend {
    [self.task suspend];
}

- (void)resume {
    [self.task resume];
}

- (void)cancel {
    [self.task cancel];
}

#pragma mark NSProgress Tracking

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if (object == self.downloadProgress) {
        if (self.downloadProgressBlock) {
            self.downloadProgressBlock(self, object);
        }
    }
    else if (object == self.uploadProgress) {
        if (self.uploadProgressBlock) {
            self.uploadProgressBlock(self, object);
        }
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    RFAPI *manager = self.manager;
    NSAssert(manager, nil);
    self.manager = nil;

    NSData *data = self.mutableData;
    if (data) {
        self.mutableData = nil;
    }

    [manager _RFAPI_handleTaskComplete:self response:task.response data:data error:error];
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    self.downloadProgress.totalUnitCount = dataTask.countOfBytesExpectedToReceive;
    self.downloadProgress.completedUnitCount = dataTask.countOfBytesReceived;

    [self.mutableData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {

    self.uploadProgress.totalUnitCount = task.countOfBytesExpectedToSend;
    self.uploadProgress.completedUnitCount = task.countOfBytesSent;
}

#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    self.downloadProgress.totalUnitCount = totalBytesExpectedToWrite;
    self.downloadProgress.completedUnitCount = totalBytesWritten;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {

    self.downloadProgress.totalUnitCount = expectedTotalBytes;
    self.downloadProgress.completedUnitCount = fileOffset;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    self.downloadFileURL = nil;

    if (self.downloadTaskDidFinishDownloading) {
        NSURL *fileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        self.downloadFileURL = fileURL;
        if (fileURL) {
            NSError *fileManagerError = nil;
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&fileManagerError];
        }
    }
}

@end
