
#import "RFAPIDefine.h"

@implementation RFAPIDefine

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, name = %@, path = %@>", self.class, (void *)self, self.name, self.path];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %p,\n"
            "\t name = %@,\n"
            "\t baseURL = %@,\n"
            "\t pathPrefix = %@,\n"
            "\t path = %@,\n"
            "\t method = %@,\n"
            "\t HTTPRequestHeaders = %@,\n"
            "\t defaultParameters = %@,\n"
            "\t needsAuthorization = %@,\n"
            "\t requestSerializerClass = %@,\n"
            "\t cachePolicy = %d,\n"
            "\t expire = %f,\n"
            "\t offlinePolicy = %d,\n"
            "\t responseSerializerClass = %@,\n"
            "\t responseExpectType = %@,\n"
            "\t responseAcceptNull = %@,\n"
            "\t responseClass = %@,\n"
            "\t userInfo = %@\n"
            "\t notes = %@\n"
            ">", self.class, (void *)self, self.name,
            self.baseURL, self.pathPrefix, self.path, self.method,
            self.HTTPRequestHeaders, self.defaultParameters, @(self.needsAuthorization),
            self.responseSerializerClass,
            self.cachePolicy, self.expire, self.offlinePolicy,
            self.responseSerializerClass, @(self.responseExpectType), @(self.responseAcceptNull), self.responseClass,
            self.userInfo, self.notes];
}

- (void)setBaseURL:(NSURL *)baseURL {
    if (_baseURL != baseURL) {
        // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
        if (baseURL.path.length && ![baseURL.absoluteString hasSuffix:@"/"]) {
            baseURL = [baseURL URLByAppendingPathComponent:@""];
        }

        _baseURL = baseURL.copy;
    }
}

- (void)setMethod:(NSString *)method {
    if (!method) {
        _method = nil;
        return;
    }
    NSAssert(method.length, @"Method can not be empty string.");

    if (_method != method) {
        _method = [method uppercaseString];
    }
}

#pragma mark - NSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    self.name = [decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, name)];
    self.baseURL = [decoder decodeObjectOfClass:[NSURL class] forKey:@keypath(self, baseURL)];
    self.pathPrefix = [decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, pathPrefix)];
    self.path = [decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, path)];
    self.method = [decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, method)];
    self.HTTPRequestHeaders = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@keypath(self, HTTPRequestHeaders)];
    self.defaultParameters = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@keypath(self, defaultParameters)];
    self.needsAuthorization = [(NSNumber *)[decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, needsAuthorization)] boolValue];
    self.requestSerializerClass = NSClassFromString((id)[decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, requestSerializerClass)]);
    self.cachePolicy = [(NSNumber *)[decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, cachePolicy)] shortValue];
    self.expire = [(NSNumber *)[decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, expire)] doubleValue];
    self.offlinePolicy = [(NSNumber *)[decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, offlinePolicy)] shortValue];
    self.responseSerializerClass = NSClassFromString((id)[decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, responseSerializerClass)]);
    self.responseExpectType = [(NSNumber *)[decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, responseExpectType)] shortValue];
    self.responseAcceptNull = [(NSNumber *)[decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, responseExpectType)] boolValue];
    self.responseClass = NSClassFromString((id)[decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, responseClass)]);
    self.userInfo = [decoder decodeObjectOfClass:[NSDictionary class] forKey:@keypath(self, userInfo)];
    self.notes = [decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, notes)];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@keypath(self, name)];
    [aCoder encodeObject:self.baseURL forKey:@keypath(self, baseURL)];
    [aCoder encodeObject:self.pathPrefix forKey:@keypath(self, pathPrefix)];
    [aCoder encodeObject:self.path forKey:@keypath(self, path)];
    [aCoder encodeObject:self.method forKey:@keypath(self, method)];
    [aCoder encodeObject:self.HTTPRequestHeaders forKey:@keypath(self, HTTPRequestHeaders)];
    [aCoder encodeObject:self.defaultParameters forKey:@keypath(self, defaultParameters)];
    [aCoder encodeObject:@(self.needsAuthorization) forKey:@keypath(self, needsAuthorization)];
    [aCoder encodeObject:@(self.cachePolicy) forKey:@keypath(self, cachePolicy)];
    [aCoder encodeObject:@(self.expire) forKey:@keypath(self, expire)];
    [aCoder encodeObject:@(self.offlinePolicy) forKey:@keypath(self, offlinePolicy)];
    [aCoder encodeObject:@(self.responseExpectType) forKey:@keypath(self, responseExpectType)];
    [aCoder encodeObject:@(self.responseAcceptNull) forKey:@keypath(self, responseAcceptNull)];
    [aCoder encodeObject:self.userInfo forKey:@keypath(self, userInfo)];
    [aCoder encodeObject:self.notes forKey:@keypath(self, notes)];

    Class aClass;
    aClass = self.requestSerializerClass;
    if (aClass) {
        [aCoder encodeObject:NSStringFromClass(aClass) forKey:@keypath(self, requestSerializerClass)];
    }
    aClass = self.responseSerializerClass;
    if (aClass) {
        [aCoder encodeObject:NSStringFromClass(aClass) forKey:@keypath(self, responseSerializerClass)];
    }
    aClass = self.responseClass;
    if (aClass) {
        [aCoder encodeObject:NSStringFromClass(aClass) forKey:@keypath(self, responseClass)];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    RFAPIDefine *clone = [(RFAPIDefine *)[self.class allocWithZone:zone] init];

    clone.name = self.name;

    clone.baseURL = self.baseURL;
    clone.pathPrefix = self.pathPrefix;
    clone.path = self.path;
    clone.method = self.method;
    clone.HTTPRequestHeaders = self.HTTPRequestHeaders;

    clone.defaultParameters = self.defaultParameters;
    clone.needsAuthorization = self.needsAuthorization;
    clone.requestSerializerClass = self.requestSerializerClass;

    clone.cachePolicy = self.cachePolicy;
    clone.expire = self.expire;
    clone.offlinePolicy = self.offlinePolicy;

    clone.responseSerializerClass = self.responseSerializerClass;
    clone.responseExpectType = self.responseExpectType;
    clone.responseAcceptNull = self.responseAcceptNull;
    clone.responseClass = self.responseClass;

    clone.userInfo = self.userInfo;
    clone.notes = self.notes;
    
    return clone;
}

@end


@implementation RFAPIDefine (RFConfigFile)

static inline NSString *_ruleStrKey(NSDictionary *rule, RFAPIDefineKey key) {
    NSString *v = rule[key];
    if (![v isKindOfClass:NSString.class]) return nil;
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

    id value;

#define RFAPIDefineConfigFileValue_(KEY)\
    value = nil;\
    if ((value = rule[KEY]))

#define RFAPIDefineConfigFileClassProperty_(PROPERTY, KEY)\
    RFAPIDefineConfigFileValue_(KEY) {\
    Class aClass = NSClassFromString(value);\
    if (aClass) {\
    self.PROPERTY = aClass;\
    }\
    else {\
    dout_warning(@"Can not get class from name: %@", value);\
    }\
    }

    NSString *baseURLString = _ruleStrKey(rule, RFAPIDefineBaseKey);
    if (baseURLString) {
        self.baseURL = [NSURL URLWithString:baseURLString];
    }
    self.pathPrefix = _ruleStrKey(rule, RFAPIDefinePathPrefixKey);
    self.path = _ruleStrKey(rule, RFAPIDefinePathKey);
    self.method = _ruleStrKey(rule, RFAPIDefineMethodKey);

    self.HTTPRequestHeaders = _ruleDicKey(rule, RFAPIDefineHeadersKey);
    self.defaultParameters = _ruleDicKey(rule, RFAPIDefineParametersKey);

    RFAPIDefineConfigFileValue_(RFAPIDefineAuthorizationKey) {
        self.needsAuthorization = [(NSNumber *)value boolValue];
    }
    RFAPIDefineConfigFileClassProperty_(requestSerializerClass, RFAPIDefineRequestSerializerKey)

    RFAPIDefineConfigFileValue_(RFAPIDefineResponseTypeKey) {
        self.responseExpectType = [(NSNumber *)value intValue];
    }
    RFAPIDefineConfigFileValue_(RFAPIDefineResponseAcceptNullKey) {
        self.responseAcceptNull = [(NSNumber *)value boolValue];
    }
    RFAPIDefineConfigFileClassProperty_(responseSerializerClass, RFAPIDefineResponseSerializerKey)

    RFAPIDefineConfigFileClassProperty_(responseClass, RFAPIDefineResponseClassKey)
    self.userInfo = _ruleDicKey(rule, RFAPIDefineUserInfoKey);
    self.notes = _ruleStrKey(rule, RFAPIDefineNotesKey);

#undef RFAPIDefineConfigFileValue_
#undef RFAPIDefineConfigFileProperty_
#undef RFAPIDefineConfigFileDictionaryProperty_
#undef RFAPIDefineConfigFileClassProperty_
#undef RFAPIDefineConfigFileEnumCase_
    return self;
}

@end
