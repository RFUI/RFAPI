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

@interface _RFAPISessionTask : NSObject <
    RFAPITask,
    NSURLSessionTaskDelegate,
    NSURLSessionDataDelegate,
    NSURLSessionDownloadDelegate
>
@property (weak, nullable) _RFURLSessionManager *manager;
@property (readonly, nonnull) NSURLSessionTask *task;

@property (nonnull) NSProgress *uploadProgress;
@property (nonnull) NSProgress *downloadProgress;
@property (nullable) void (^uploadProgressBlock)(NSProgress *__nonnull);
@property (nullable) void (^downloadProgressBlock)(NSProgress *__nonnull);

@property (nullable) void (^completionHandler)(NSURLResponse *__nullable response, id __nullable responseObject, NSError *__nullable error);

@property (copy, nullable) NSURL *downloadFileURL;
@property (nullable) NSURL *__nullable (^downloadTaskDidFinishDownloading)(NSURLSession *__nonnull session, NSURLSessionDownloadTask *__nonnull downloadTask, NSURL *__nonnull location);

- (nonnull instancetype)initWithTask:(nonnull NSURLSessionTask *)task;
@end
