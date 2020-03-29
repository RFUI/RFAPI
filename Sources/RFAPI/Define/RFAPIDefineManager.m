
#import "RFAPIDefineManager.h"
#import "RFAPIPrivate.h"
#import "RFAPIDefineConfigFile.h"
#import <AFNetworking/AFURLRequestSerialization.h>
#import <AFNetworking/AFURLResponseSerialization.h>


@interface RFAPIDefineManager ()
@property (nonnull) NSMutableDictionary<RFAPIName, RFAPIDefine *> *_defines;
@end

@implementation RFAPIDefineManager

+ (NSRegularExpression *)cachedPathParameterRegularExpression {
    static NSRegularExpression *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[NSRegularExpression alloc] initWithPattern:@"\\{[\\w-]+\\}" options:NSRegularExpressionAnchorsMatchLines error:nil];
        NSAssert(sharedInstance, @"Cannot create path parameter regular expression");
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        __defines = [NSMutableDictionary.alloc initWithCapacity:64];
        _authorizationHeader = [NSMutableDictionary.alloc initWithCapacity:2];
        _authorizationParameters = [NSMutableDictionary.alloc initWithCapacity:2];
    }
    return self;
}

- (RFAPIDefine *)defineForName:(RFAPIName)defineName {
    if (!defineName) return nil;
    @synchronized(self) {
        return self._defines[defineName];
    }
}

@dynamic defines;
- (NSArray<RFAPIDefine *> *)defines {
    @synchronized(self) {
        return self._defines.allValues;
    }
}
- (void)setDefines:(NSArray<RFAPIDefine *> *)defines {
    @synchronized(self) {
        NSMutableDictionary *newDefines = self._defines;
        [newDefines removeAllObjects];

        for (RFAPIDefine *d in defines) {
            RFAPIName name = d.name;
            if (!name) {
                NSAssert(false, @"API Define no name: %@", d);
                continue;
            }
            newDefines[name] = d;
        }
    }
}

#pragma mark - RFAPI Support

- (NSURL *)requestURLForDefine:(RFAPIDefine *)define parameters:(NSMutableDictionary *)parameters error:(NSError *__autoreleasing *)error {
    NSMutableString *path = define.path.mutableCopy;
    if (!path) {
        if (error) {
            *error = [RFAPI localizedErrorWithDoomain:NSURLErrorDomain code:NSURLErrorBadURL underlyingError:nil descriptionKey:@"RFAPI.Error.DefineNoPath" descriptionValue:@"API define path is nil" reasonKey:@"RFAPI.Error.GeneralFailureReasonApp" reasonValue:nil suggestionKey:@"RFAPI.Error.GeneralRecoverySuggestion" suggestionValue:nil url:nil];
        }
        return nil;
    }

    // Replace {PARAMETER} in path
    NSArray *matches = [RFAPIDefineManager.cachedPathParameterRegularExpression matchesInString:path options:kNilOptions range:NSMakeRange(0, path.length)];

    for (NSTextCheckingResult *match in matches.reverseObjectEnumerator) {
        NSRange keyRange = match.range;
        keyRange.location++;
        keyRange.length -= 2;
        NSString *key = [path substringWithRange:keyRange];

        id parameter = parameters[key];
        if (parameter) {
            NSString *encodedParameter = [[(NSObject *)parameter description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [path replaceCharactersInRange:match.range withString:encodedParameter];
            [parameters removeObjectForKey:key];
        }
        else {
            [path replaceCharactersInRange:match.range withString:@""];
        }
    }
    
    NSURL *url = [NSURL.alloc initWithString:path];
    if (!url.scheme.length) {
        NSString *URLString = define.pathPrefix? [define.pathPrefix stringByAppendingString:path] : path;
        url = [NSURL.alloc initWithString:URLString relativeToURL:define.baseURL];
    }
    
    if (!url) {
        NSString *debugFormat = [RFAPI localizedStringForKey:@"RFAPI.Debug.CannotJoinPathToBaseURL" value:@"Unable to join path %1$@ to %2$@, please check the API define"];
        RFAPILogError_(debugFormat, path, define.baseURL)
        if (error) {
            *error = [RFAPI localizedErrorWithDoomain:NSURLErrorDomain code:NSURLErrorBadURL underlyingError:nil descriptionKey:@"RFAPI.Error.CannotCreateRequestDescription" descriptionValue:@"Internal error, unable to create request" reasonKey:@"RFAPI.Error.CannotCreateRequestReason" reasonValue:@"It seems to be an application bug" suggestionKey:@"RFAPI.Error.CannotCreateRequestSuggestion" suggestionValue:@"Please try again. If it still doesn't work, try restarting the application" url:nil];
        }
        return nil;
    }

    NSDictionary *forceQuryStringParameters = parameters[RFAPIRequestForceQuryStringParametersKey];
    if (forceQuryStringParameters) {
        [parameters removeObjectForKey:RFAPIRequestForceQuryStringParametersKey];
        NSMutableArray *queryStringPair = [NSMutableArray.alloc initWithCapacity:forceQuryStringParameters.count];
        for (NSString *key in forceQuryStringParameters.allKeys) {
            [queryStringPair addObject:[NSString stringWithFormat:@"%@=%@", key, forceQuryStringParameters[key]]];
        }
        NSString *query = [queryStringPair componentsJoinedByString:@"&"];
        NSString *urlString = [url.absoluteString stringByAppendingFormat:url.query.length ? @"&%@" : @"?%@", query];
        url = [NSURL.alloc initWithString:urlString];
    }
    
    return url;
}

- (id<AFURLRequestSerialization>)defaultRequestSerializer {
    if (!_defaultRequestSerializer) {
        _defaultRequestSerializer = [AFJSONRequestSerializer serializer];
    }
    return _defaultRequestSerializer;
}
- (id<AFURLResponseSerialization>)defaultResponseSerializer {
    if (!_defaultResponseSerializer) {
        _defaultResponseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    }
    return _defaultResponseSerializer;
}

- (id<AFURLRequestSerialization>)requestSerializerForDefine:(RFAPIDefine *)define {
    if (define.requestSerializerClass) {
        return [define.requestSerializerClass serializer];
    }
    return self.defaultRequestSerializer;
}
- (id<AFURLResponseSerialization>)responseSerializerForDefine:(RFAPIDefine *)define {
    if (define.responseSerializerClass) {
        return [define.responseSerializerClass serializer];
    }
    return self.defaultResponseSerializer;
}

@end
