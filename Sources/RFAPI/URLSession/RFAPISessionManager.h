/*
RFAPISessionManager
RFAPI

Copyright © 2019 BB9z
https://github.com/RFUI/RFAPI

The MIT License (MIT)
http://www.opensource.org/licenses/mit-license.php
*/

#import <AFNetworking/AFHTTPSessionManager.h>

@class AFHTTPRequestSerializer;
@class AFHTTPResponseSerializer;

@class _RFAPISessionTask;

@interface _RFURLSessionManager : NSObject <
    NSURLSessionDelegate,
    NSURLSessionTaskDelegate,
    NSURLSessionDataDelegate,
    NSURLSessionDownloadDelegate
>

/**
 Creates and returns a manager for a session created with the specified configuration. This is the designated initializer.

 @param configuration The configuration used to create the managed session.

 @return A manager for a newly-created session.
 */
- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/**
 The managed session.
 */
@property (readonly, nonnull) NSURLSession *session;

/**
 Default request serializer.

 Default value is an `AFJSONRequestSerializer`.
 */
@property (null_resettable, nonatomic) __kindof AFHTTPRequestSerializer <AFURLRequestSerialization> *requestSerializer;

/**
 Default response serializer.

 Default value is an `AFJSONResponseSerializer`.
 */
@property (null_resettable, nonatomic) __kindof AFHTTPResponseSerializer <AFURLResponseSerialization> *responseSerializer;

///-------------------------------
/// @name Managing Security Policy
///-------------------------------

/**
 The security policy used by created session to evaluate server trust for secure connections. `AFURLSessionManager` uses the `defaultPolicy` unless otherwise specified.
 */
@property (null_resettable, nonatomic) AFSecurityPolicy *securityPolicy;

#pragma mark - Queue

/**
 The operation queue on which delegate callbacks are run.
 */
@property (readonly, nonnull) NSOperationQueue *operationQueue;

#pragma mark - Session Tasks

/**
 The data, upload, and download tasks currently run by the managed session.
 */
@property (readonly, nonnull, nonatomic) NSArray <NSURLSessionTask *> *tasks;

/**
 The data tasks currently run by the managed session.
 */
@property (readonly, nonnull, nonatomic) NSArray <NSURLSessionDataTask *> *dataTasks;

/**
 The upload tasks currently run by the managed session.
 */
@property (readonly, nonnull, nonatomic) NSArray <NSURLSessionUploadTask *> *uploadTasks;

/**
 The download tasks currently run by the managed session.
 */
@property (readonly, nonnull, nonatomic) NSArray <NSURLSessionDownloadTask *> *downloadTasks;

/**
 Invalidates the managed session, optionally canceling pending tasks.

 @param cancelPendingTasks Whether or not to cancel pending tasks.
 */
- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks;

#pragma mark - API Tasks

- (nonnull NSArray<_RFAPISessionTask *> *)allTasks;

- (nullable _RFAPISessionTask *)addSessionTask:(nullable NSURLSessionTask *)sessionTask;

#pragma mark - Getting Progress for Tasks

/**
 Returns the upload progress of the specified task.

 @param task The session task. Must not be `nil`.

 @return An `NSProgress` object reporting the upload progress of a task, or `nil` if the progress is unavailable.
 */
- (nullable NSProgress *)uploadProgressForTask:(nonnull NSURLSessionTask *)task;

/**
 Returns the download progress of the specified task.

 @param task The session task. Must not be `nil`.

 @return An `NSProgress` object reporting the download progress of a task, or `nil` if the progress is unavailable.
 */
- (nullable NSProgress *)downloadProgressForTask:(nonnull NSURLSessionTask *)task;

#pragma mark - Callbacks

NS_ASSUME_NONNULL_BEGIN

/**
 Sets a block to be executed when the managed session becomes invalid, as handled by the `NSURLSessionDelegate` method `URLSession:didBecomeInvalidWithError:`.

 @param block A block object to be executed when the managed session becomes invalid. The block has no return value, and takes two arguments: the session, and the error related to the cause of invalidation.
 */
@property (nullable) void (^sessionDidBecomeInvalid)(NSURLSession *session, NSError *error);

/**
 Sets a block to be executed when a connection level authentication challenge has occurred, as handled by the `NSURLSessionDelegate` method `URLSession:didReceiveChallenge:completionHandler:`.

 @param block A block object to be executed when a connection level authentication challenge has occurred. The block returns the disposition of the authentication challenge, and takes three arguments: the session, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
@property (nullable) NSURLSessionAuthChallengeDisposition (^sessionDidReceiveAuthenticationChallenge)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential);

/**
 Sets a block to be executed when a task requires a new request body stream to send to the remote server, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:needNewBodyStream:`.

 @param block A block object to be executed when a task requires a new request body stream.
 */
@property (nullable) NSInputStream *__nullable (^taskNeedNewBodyStream)(NSURLSession *session, NSURLSessionTask *task);

/**
 Sets a block to be executed when an HTTP request is attempting to perform a redirection to a different URL, as handled by the `NSURLSessionTaskDelegate` method `URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`.

 @param block A block object to be executed when an HTTP request is attempting to perform a redirection to a different URL. The block returns the request to be made for the redirection, and takes four arguments: the session, the task, the redirection response, and the request corresponding to the redirection response.
 */
@property (nullable) NSURLRequest * _Nullable (^taskWillPerformHTTPRedirection)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request);

/**
 Sets a block to be executed when a session task has received a request specific authentication challenge, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didReceiveChallenge:completionHandler:`.

 @param block A block object to be executed when a session task has received a request specific authentication challenge. The block returns the disposition of the authentication challenge, and takes four arguments: the session, the task, the authentication challenge, and a pointer to the credential that should be used to resolve the challenge.
 */
@property (nullable) NSURLSessionAuthChallengeDisposition (^taskDidReceiveAuthenticationChallenge)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential);

/**
 Sets a block to be executed periodically to track upload progress, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`.

 @param block A block object to be called when an undetermined number of bytes have been uploaded to the server. This block has no return value and takes five arguments: the session, the task, the number of bytes written since the last time the upload progress block was called, the total bytes written, and the total bytes expected to be written during the request, as initially determined by the length of the HTTP body. This block may be called multiple times, and will execute on the main thread.
 */
@property (nullable) void (^taskDidSendBodyData)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);

/**
 Sets a block to be executed as the last message related to a specific task, as handled by the `NSURLSessionTaskDelegate` method `URLSession:task:didCompleteWithError:`.

 @param block A block object to be executed when a session task is completed. The block has no return value, and takes three arguments: the session, the task, and any error that occurred in the process of executing the task.
 */
@property (nullable) void (^taskDidComplete)(NSURLSession *session, NSURLSessionTask *task, NSError * _Nullable error);

/**
 Sets a block to be executed when a data task has received a response, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveResponse:completionHandler:`.

 @param block A block object to be executed when a data task has received a response. The block returns the disposition of the session response, and takes three arguments: the session, the data task, and the received response.
 */
@property (nullable) NSURLSessionResponseDisposition (^dataTaskDidReceiveResponse)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response);

/**
 Sets a block to be executed when a data task has become a download task, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didBecomeDownloadTask:`.

 @param block A block object to be executed when a data task has become a download task. The block has no return value, and takes three arguments: the session, the data task, and the download task it has become.
 */
@property (nullable) void (^dataTaskDidBecomeDownloadTask)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask);

/**
 Sets a block to be executed when a data task receives data, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`.

 @param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes three arguments: the session, the data task, and the data received. This block may be called multiple times, and will execute on the session manager operation queue.
 */
@property (nullable) void (^dataTaskDidReceiveData)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);

/**
 Sets a block to be executed to determine the caching behavior of a data task, as handled by the `NSURLSessionDataDelegate` method `URLSession:dataTask:willCacheResponse:completionHandler:`.

 @param block A block object to be executed to determine the caching behavior of a data task. The block returns the response to cache, and takes three arguments: the session, the data task, and the proposed cached URL response.
 */
@property (nullable) NSCachedURLResponse * (^dataTaskWillCacheResponse)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse);

/**
Sets a block to be executed when a download task has completed a download, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didFinishDownloadingToURL:`.

@param block A block object to be executed when a download task has completed. The block returns the URL the download should be moved to, and takes three arguments: the session, the download task, and the temporary location of the downloaded file. If the file manager encounters an error while attempting to move the temporary file to the destination, an `AFURLSessionDownloadTaskDidFailToMoveFileNotification` will be posted, with the download task as its object, and the user info of the error.
*/
@property (nullable) NSURL * _Nullable (^downloadTaskDidFinishDownloading)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);

/**
Sets a block to be executed periodically to track download progress, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesWritten:totalBytesExpectedToWrite:`.

@param block A block object to be called when an undetermined number of bytes have been downloaded from the server. This block has no return value and takes five arguments: the session, the download task, the number of bytes read since the last time the download progress block was called, the total bytes read, and the total bytes expected to be read during the request, as initially determined by the expected content size of the `NSHTTPURLResponse` object. This block may be called multiple times, and will execute on the session manager operation queue.
*/
@property (nullable) void (^downloadTaskDidWriteData)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

/**
Sets a block to be executed when a download task has been resumed, as handled by the `NSURLSessionDownloadDelegate` method `URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`.

@param block A block object to be executed when a download task has been resumed. The block has no return value and takes four arguments: the session, the download task, the file offset of the resumed download, and the total number of bytes expected to be downloaded.
*/
@property (nullable) void (^downloadTaskDidResume)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes);

NS_ASSUME_NONNULL_END
@end
