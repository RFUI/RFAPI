
#import "RFAPIDefineConfigFile.h"
#import "RFAPIPrivate.h"

NSString *const RFAPIDefineDefaultKey       = @"DEFAULT";

RFAPIDefineKey const RFAPIDefineNameKey          = @"Name";
RFAPIDefineKey const RFAPIDefineBaseKey          = @"Base";
RFAPIDefineKey const RFAPIDefinePathPrefixKey    = @"Path Prefix";
RFAPIDefineKey const RFAPIDefinePathKey          = @"Path";
RFAPIDefineKey const RFAPIDefineMethodKey        = @"Method";
RFAPIDefineKey const RFAPIDefineHeadersKey       = @"Headers";

RFAPIDefineKey const RFAPIDefineParametersKey    = @"Parameters";
RFAPIDefineKey const RFAPIDefineAuthorizationKey = @"Authorization";
RFAPIDefineKey const RFAPIDefineRequestSerializerKey = @"Serializer";

RFAPIDefineKey const RFAPIDefineCachePolicyKey   = @"Cache Policy";
RFAPIDefineKey const RFAPIDefineExpireKey        = @"Expire";
RFAPIDefineKey const RFAPIDefineOfflinePolicyKey = @"Offline Policy";

RFAPIDefineKey const RFAPIDefineResponseSerializerKey = @"Response Serializer";
RFAPIDefineKey const RFAPIDefineResponseTypeKey  = @"Response Type";
RFAPIDefineKey const RFAPIDefineResponseAcceptNullKey = @"Response Accept Null";
RFAPIDefineKey const RFAPIDefineResponseClassKey = @"Response Class";

RFAPIDefineKey const RFAPIDefineUserInfoKey      = @"User Info";
RFAPIDefineKey const RFAPIDefineNotesKey         = @"Notes";


@implementation RFAPIDefine (RFConfigFile)

static inline NSString *_ruleStrKey(NSDictionary *rule, RFAPIDefineKey key) {
    NSString *v = rule[key];
    if (![v isKindOfClass:NSString.class]) return nil;
    return v;
}

static inline NSNumber *_ruleNumberKey(NSDictionary *rule, RFAPIDefineKey key) {
    NSNumber *v = rule[key];
    if (![v isKindOfClass:NSNumber.class]) return nil;
    return v;
}

static inline NSDictionary *_ruleDicKey(NSDictionary *rule, RFAPIDefineKey key) {
    NSDictionary *v = rule[key];
    if (![v isKindOfClass:NSDictionary.class]) return nil;
    return v;
}

- (instancetype)initWithRule:(NSDictionary *)rule name:(NSString *)name {
    NSParameterAssert(name);
    NSParameterAssert(rule);
    self = [self init];
    self.name = name;

    NSString *baseURLString = _ruleStrKey(rule, RFAPIDefineBaseKey);
    if (baseURLString) {
        self.baseURL = [NSURL URLWithString:baseURLString];
    }
    self.pathPrefix = _ruleStrKey(rule, RFAPIDefinePathPrefixKey);
    self.path = _ruleStrKey(rule, RFAPIDefinePathKey);
    self.method = _ruleStrKey(rule, RFAPIDefineMethodKey);

    self.HTTPRequestHeaders = _ruleDicKey(rule, RFAPIDefineHeadersKey);
    self.defaultParameters = _ruleDicKey(rule, RFAPIDefineParametersKey);

    self.needsAuthorizationValue = _ruleNumberKey(rule, RFAPIDefineAuthorizationKey);
    NSString *class = _ruleStrKey(rule, RFAPIDefineRequestSerializerKey);
    if (class) {
        self.requestSerializerClass = NSClassFromString(class);
        NSAssert(self.requestSerializerClass, @"Can not create requestSerializerClass from name: %@", class);
    }
    class = _ruleStrKey(rule, RFAPIDefineResponseSerializerKey);
    if (class) {
        self.responseSerializerClass = NSClassFromString(class);
        NSAssert(self.responseSerializerClass, @"Can not create responseSerializerClass from name: %@", class);
    }
    self.cachePolicyValue = _ruleNumberKey(rule, RFAPIDefineCachePolicyKey);
    self.cacheExpireValue = _ruleNumberKey(rule, RFAPIDefineExpireKey);
    self.offlinePolicyValue = _ruleNumberKey(rule, RFAPIDefineResponseTypeKey);
    self.responseExpectTypeValue = _ruleNumberKey(rule, RFAPIDefineResponseTypeKey);
    self.responseAcceptNullValue = _ruleNumberKey(rule, RFAPIDefineResponseAcceptNullKey);
    self.responseClass = _ruleStrKey(rule, RFAPIDefineResponseClassKey);

    self.userInfo = _ruleDicKey(rule, RFAPIDefineUserInfoKey);
    self.notes = _ruleStrKey(rule, RFAPIDefineNotesKey);

    return self;
}

@end


@implementation RFAPIDefineManager (RFConfigFile)

- (void)setDefinesWithRulesInfo:(NSDictionary<NSString *, NSDictionary<NSString *,id> *> *)rules {
    NSParameterAssert(rules);

    NSMutableDictionary<RFAPIName, RFAPIDefineRawConfig> *prules = [NSMutableDictionary.alloc initWithCapacity:64];
    __block NSInteger ruleCount = 0;
    [rules enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary<NSString *,id> *obj, BOOL *stop) {
#if RFDEBUG
        NSAssert([obj isKindOfClass:NSDictionary.class], @"All items in define configuration should be dictionaries. Current: %@", obj);
#endif
        if ([key hasPrefix:@"@"]) {
#if RFDEBUG
            for (RFAPIDefineRawConfig item in obj.allValues) {
                NSAssert([item isKindOfClass:NSDictionary.class], @"Items that begin with the @ character are treated as group. All items in a group should be dictionaries. Current: %@", item);
            }
#endif
            [prules addEntriesFromDictionary:obj];

            ruleCount += obj.count;
        }
        else {
            prules[key] = obj;
            ruleCount++;
        }
    }];
    RFAssert(ruleCount == prules.count, @"There are defines with the same name.")

    NSMutableArray<RFAPIDefine *> *defines = [NSMutableArray.alloc initWithCapacity:prules.count];
    RFAPIDefineRawConfig defaultRule = prules[RFAPIDefineDefaultKey];
    [prules enumerateKeysAndObjectsUsingBlock:^(RFAPIName  _Nonnull key, RFAPIDefineRawConfig  _Nonnull obj, BOOL * _Nonnull stop) {
        [defines addObject:[RFAPIDefine.alloc initWithRule:obj name:key]];
    }];
    if (defaultRule) {
        self.defaultDefine = [RFAPIDefine.alloc initWithRule:defaultRule name:RFAPIDefineDefaultKey];
    }
    self.defines = defines;
}

@end
