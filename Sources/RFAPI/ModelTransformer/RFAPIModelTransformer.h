/*
RFAPIModelTransformer
RFAPI

Copyright © 2019-2020 BB9z
https://github.com/RFUI/RFAPI

The MIT License (MIT)
http://www.opensource.org/licenses/mit-license.php
*/

#import "RFAPIDefine.h"

@protocol RFAPIModelTransformer <NSObject>
@required

- (nullable id)transformResponse:(nonnull id)response toType:(RFAPIDefineResponseExpectType)type kind:(nullable NSString *)modelKind error:(NSError *__nullable *__nonnull)error;

@end
