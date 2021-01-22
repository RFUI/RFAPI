/*
RFAPISessionTask
RFAPI

Copyright © 2019-2021 BB9z
https://github.com/RFUI/RFAPI

The MIT License (MIT)
http://www.opensource.org/licenses/mit-license.php
*/

#import "RFAPIPrivate.h"

@class _RFURLSessionManager;
@class RFNetworkActivityMessage;

typedef void(^RFAPITaskComplation)(id __nullable responseObject, NSURLResponse *__nullable response, NSError *__nullable error);

/**
 Private object manage status.

 Some properties will be set to nil after use to save memory.
 */
@interface _RFAPISessionTask : NSObject <
    RFAPITask,
    NSURLSessionTaskDelegate,
    NSURLSessionDataDelegate,
    NSURLSessionDownloadDelegate
>

@property (nonnull) NSURLSessionTask *task;

#pragma mark -

@property (nullable) RFAPI *manager;
@property (nonnull) RFAPIDefine *define;

@property (nonnull) NSString *identifier;
@property (nullable) NSString *groupIdentifier;
@property (nullable) RFNetworkActivityMessage *activityMessage;

/// Set nil when task finished.
@property (nullable) NSArray<id> *bindControls;
- (void)updateBindControlsEnabled:(BOOL)enabled;

/// From request context.
@property (nullable) NSDictionary *userInfo;
@property NSTimeInterval debugDelayRequestSend;

@property (nullable) id __nullable (^responseObjectTransformer)(RFAPIDefine *__nonnull define, id __nullable responseObject);

#pragma mark - States

@property (readonly, copy, nullable, nonatomic) NSURLRequest *currentRequest;
@property (readonly, copy, nullable, nonatomic) NSURLRequest *originalRequest;
@property (readonly, copy, nullable, nonatomic) NSURLResponse *response;
@property (nullable) id responseObject;
@property (nullable) NSError *error;
@property BOOL isSuccess;

/// 
@property (readonly, nonatomic) BOOL isEnd;

@property (nonnull) NSProgress *uploadProgress;
@property (nonnull) NSProgress *downloadProgress;
@property (nullable) RFAPIRequestProgressBlock uploadProgressBlock;
@property (nullable) RFAPIRequestProgressBlock downloadProgressBlock;

#pragma mark - Callback

/// Reset after use
@property (nullable) RFAPIRequestSuccessCallback success;
/// Reset after use
@property (nullable) RFAPIRequestFailureCallback failure;
/// Reset after use
@property (nullable) RFAPIRequestFinishedCallback complation;
/// Reset after use
@property (nullable) RFAPIRequestCombinedCompletionCallback combinedComplation;


// NO implementation
@property (copy, nullable) NSURL *downloadFileURL;
// NO implementation
@property (nullable) NSURL *__nullable (^downloadTaskDidFinishDownloading)(NSURLSession *__nonnull session, NSURLSessionDownloadTask *__nonnull downloadTask, NSURL *__nonnull location);

@end
