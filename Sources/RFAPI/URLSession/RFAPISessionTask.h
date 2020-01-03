/*
RFAPISessionTask
RFAPI

Copyright © 2019 BB9z
https://github.com/RFUI/RFAPI

The MIT License (MIT)
http://www.opensource.org/licenses/mit-license.php
*/

#import "RFAPIPrivate.h"

@class _RFURLSessionManager;
@class RFNetworkActivityMessage;

typedef void(^RFAPITaskComplation)(id __nullable responseObject, NSURLResponse *__nullable response, NSError *__nullable error);

@interface _RFAPISessionTask : NSObject <
    RFAPITask,
    NSURLSessionTaskDelegate,
    NSURLSessionDataDelegate,
    NSURLSessionDownloadDelegate
>

- (nonnull instancetype)initWithTask:(nonnull NSURLSessionTask *)task;

@property (nonnull) NSURLSessionTask *task;

#pragma mark -

@property (weak, nullable) RFAPI *manager;
@property (nonnull) RFAPIDefine *define;

@property (nonnull) NSString *identifier;
@property (nullable) NSString *groupIdentifier;
@property (nullable) RFNetworkActivityMessage *activityMessage;

#pragma mark - States

/// 
@property (readonly, nonatomic) BOOL isEnd;

@property (nonnull) NSProgress *uploadProgress;
@property (nonnull) NSProgress *downloadProgress;
@property (nullable) RFAPIRequestProgressBlock uploadProgressBlock;
@property (nullable) RFAPIRequestProgressBlock downloadProgressBlock;

@property (nullable) void (^completionHandler)(NSURLResponse *__nullable response, id __nullable responseObject, NSError *__nullable error);

#pragma mark - Callback

@property (nullable) RFAPIRequestSuccessCallback success;
@property (nullable) RFAPIRequestFailureCallback failure;
@property (nullable) RFAPIRequestCompletionCallback complation;

@property (copy, nullable) NSURL *downloadFileURL;
@property (nullable) NSURL *__nullable (^downloadTaskDidFinishDownloading)(NSURLSession *__nonnull session, NSURLSessionDownloadTask *__nonnull downloadTask, NSURL *__nonnull location);

@end
