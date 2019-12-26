/*!
 RFAPIDefineConfigFileKeys
 RFAPI
 
 Copyright (c) 2014, 2018-2019 BB9z
 https://github.com/RFUI/RFAPI
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */
#import <Foundation/Foundation.h>

typedef NSString * RFAPIDefineKey;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineDefaultKey;               /// DEFAULT

FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineNameKey;                  /// Name
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineBaseKey;                  /// Base
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefinePathPrefixKey;            /// Path Prefix
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefinePathKey;                  /// Path
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineMethodKey;                /// Method
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineHeadersKey;               /// Headers

FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineParametersKey;            /// Parameters
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineAuthorizationKey;         /// Authorization
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineRequestSerializerKey;     /// Serializer

FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineCachePolicyKey;           /// Cache Policy
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineExpireKey;                /// Expire
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineOfflinePolicyKey;         /// Offline Policy

FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineResponseSerializerKey;    /// Response Serializer
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineResponseTypeKey;          /// Response Type
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineResponseAcceptNullKey;    /// Response Accept Null
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineResponseClassKey;         /// Response Class

FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineUserInfoKey;              /// User Info
FOUNDATION_EXTERN RFAPIDefineKey const RFAPIDefineNotesKey;                 /// Notes

NS_ASSUME_NONNULL_END
