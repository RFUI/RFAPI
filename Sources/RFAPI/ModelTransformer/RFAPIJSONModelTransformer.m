
#import "RFAPIJSONModelTransformer.h"
#import "RFAPIPrivate.h"
#import <JSONModel/JSONModel.h>

@implementation RFAPIJSONModelTransformer

- (id)transformResponse:(id)response toType:(RFAPIDefineResponseExpectType)type kind:(Class)modelClass error:(NSError * _Nullable __autoreleasing *)error {
    switch (type) {
        case RFAPIDefineResponseExpectObject: {
            NSDictionary *responseObject = response;
            if (![responseObject isKindOfClass:NSDictionary.class]) {
                RFAPILogError_(@"期望的数据类型是字典，而实际是 %@\n请先确认一下代码，如果服务器没按要求返回请联系后台人员", responseObject.class)
                *error = [NSError errorWithDomain:RFAPIErrorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey: @"返回数据异常",
                    NSLocalizedFailureReasonErrorKey: @"可能服务器正在升级或者维护，也可能是应用 bug",
                    NSLocalizedRecoverySuggestionErrorKey: @"建议稍后重试，如果持续报告这个错误请检查 AppStore 是否有新版本"
                }];
                return nil;
            }

            NSError *e = nil;
            id JSONModelObject = [(JSONModel *)[modelClass alloc] initWithDictionary:responseObject error:&e];
            if (!JSONModelObject) {
                RFAPILogError_(@"不能将返回内容转换为Model：%@\n请先确认一下代码，如果服务器没按要求返回请联系后台人员", e)

                *error = [NSError errorWithDomain:RFAPIErrorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey: @"返回数据异常",
                    NSLocalizedFailureReasonErrorKey: @"可能服务器正在升级或者维护，也可能是应用 bug",
                    NSLocalizedRecoverySuggestionErrorKey: @"建议稍后重试，如果持续报告这个错误请检查 AppStore 是否有新版本"
                }];
            }
            return JSONModelObject;
        }
        case RFAPIDefineResponseExpectObjects: {
            NSArray *responseObject = response;
            if (![responseObject isKindOfClass:NSArray.class]) {
                RFAPILogError_(@"期望的数据类型是数组，而实际是 %@\n请先确认一下代码，如果服务器没按要求返回请联系后台人员", responseObject.class)
                *error = [NSError errorWithDomain:RFAPIErrorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey: @"返回数据异常",
                    NSLocalizedFailureReasonErrorKey: @"可能服务器正在升级或者维护，也可能是应用 bug",
                    NSLocalizedRecoverySuggestionErrorKey: @"建议稍后重试，如果持续报告这个错误请检查 AppStore 是否有新版本"
                }];
                return nil;
            }

            NSMutableArray *objects = [NSMutableArray.alloc initWithCapacity:responseObject.count];
            for (NSDictionary *info in responseObject) {
                id obj = [(JSONModel *)[modelClass alloc] initWithDictionary:info error:error];
                if (obj) {
                    [objects addObject:obj];
                    continue;
                }

                RFAPILogError_(@"不能将数组中的元素转换为Model %@\n请先确认一下代码，如果服务器没按要求返回请联系后台人员", *error)
                *error = [NSError errorWithDomain:RFAPIErrorDomain code:0 userInfo:@{
                    NSLocalizedDescriptionKey: @"返回数据异常",
                    NSLocalizedFailureReasonErrorKey: @"可能服务器正在升级或者维护，也可能是应用 bug",
                    NSLocalizedRecoverySuggestionErrorKey: @"建议稍后重试，如果持续报告这个错误请检查 AppStore 是否有新版本"
                }];
                return nil;
            }
            return objects;
        }
        case RFAPIDefineResponseExpectDefault:
        case RFAPIDefineResponseExpectSuccess:
        default:
            return response;
    }
}

@end
