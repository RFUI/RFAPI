
#import "RFAPIJSONModelTransformer.h"
#import "RFAPIPrivate.h"
#import <JSONModel/JSONModel.h>

@implementation RFAPIJSONModelTransformer

- (id)transformResponse:(id)response toType:(RFAPIDefineResponseExpectType)type kind:(NSString *)modelKind error:(NSError * _Nullable __autoreleasing *)error {
    Class modelClass = NSClassFromString(modelKind);
    switch (type) {
        case RFAPIDefineResponseExpectObject: {
            NSDictionary *responseObject = response;
            if (![responseObject isKindOfClass:NSDictionary.class]) {
#if RFDEBUG
                NSString *debugFormat = [RFAPI localizedStringForKey:@"RFAPI.Debug.ObjectResponseTypeMismatchClass" value:@"Server response is %@ other than a dictionary\nPlease check your code first, then contart the server staff if the sever does not return as required"];
                RFAPILogError_(debugFormat, responseObject.class)
#endif
                *error = [self badResponseError:nil];
                return nil;
            }

            NSError *e = nil;
            id JSONModelObject = [(JSONModel *)[modelClass alloc] initWithDictionary:responseObject error:&e];
            if (!JSONModelObject) {
#if RFDEBUG
                NSString *debugFormat = [RFAPI localizedStringForKey:@"RFAPI.Debug.ObjectResponseConvertToModelError" value:@"Cannot convert response to model: %@\nPlease check your code first, then contart the server staff if the sever does not return as required"];
                RFAPILogError_(debugFormat, e)
#endif
                *error = [self badResponseError:e];
            }
            return JSONModelObject;
        }
        case RFAPIDefineResponseExpectObjects: {
            NSArray *responseObject = response;
            if (![responseObject isKindOfClass:NSArray.class]) {
#if RFDEBUG
                NSString *debugFormat = [RFAPI localizedStringForKey:@"RFAPI.Debug.ArrayResponseTypeMismatchClass" value:@"Server response is %@ other than an array\nPlease check your code first, then contart the server staff if the sever does not return as required"];
                RFAPILogError_(debugFormat, responseObject.class)
#endif
                *error = [self badResponseError:nil];
                return nil;
            }

            NSMutableArray *objects = [NSMutableArray.alloc initWithCapacity:responseObject.count];
            for (NSDictionary *info in responseObject) {
                NSError *e = nil;
                id obj = [(JSONModel *)[modelClass alloc] initWithDictionary:info error:&e];
                if (obj) {
                    [objects addObject:obj];
                    continue;
                }
#if RFDEBUG
                NSString *debugFormat = [RFAPI localizedStringForKey:@"RFAPI.Debug.ObjectResponseConvertToModelError" value:@"Cannot convert elements in the array to model: %@\nPlease check your code first, then contart the server staff if the sever does not return as required"];
                RFAPILogError_(debugFormat, e)
#endif
                *error = [self badResponseError:e];
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

- (NSError *)badResponseError:(NSError *)underlyingError {
    return [RFAPI localizedErrorWithDoomain:RFAPIErrorDomain code:0 underlyingError:underlyingError descriptionKey:@"RFAPI.Error.UnexpectedServerResponse" descriptionValue:@"Unexpected server response" reasonKey:@"RFAPI.Error.GeneralFailureReasonServer" reasonValue:@"It may be the server being upgraded or maintained, or it may be an application bug" suggestionKey:@"RFAPI.Error.GeneralRecoverySuggestion" suggestionValue:@"Please try again later. Check for a new version if this error persists" url:nil];
}

@end
