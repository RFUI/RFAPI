/*
 RFAPICompatible
 RFAPI

 Copyright © 2020 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import "RFAPI.h"

/// Map v1 RFAPIControl to RFAPIRequestConext
#ifndef RFAPIControl
#define RFAPIControl RFAPIRequestConext
#endif

@interface RFAPI (V1Compatible)

- (nullable id<RFAPITask>)requestWithName:(nonnull NSString *)APIName
       parameters:(nullable NSDictionary *)parameters
      controlInfo:(nullable RFAPIControl *)controlInfo
          success:(void (^_Nullable)(id<RFAPITask> _Nullable operation, id _Nullable responseObject))success
          failure:(void (^_Nullable)(id<RFAPITask> _Nullable operation, NSError *_Nonnull error))failure
       completion:(void (^_Nullable)(id<RFAPITask> _Nullable operation))completion;

@end

@interface RFAPIControl (V1Compatible)

- (nonnull id)initWithIdentifier:(nonnull NSString *)identifier loadingMessage:(nullable NSString *)message;

@end
