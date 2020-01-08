
#import "RFAPIPrivate.h"

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

#pragma mark - Wrapper Properties

- (BOOL)needsAuthorization {
    return self.needsAuthorizationValue.boolValue;
}
- (void)setNeedsAuthorization:(BOOL)needsAuthorization {
    self.needsAuthorizationValue = @(needsAuthorization);
}

- (RFAPIDefineCachePolicy)cachePolicy {
    return self.cachePolicyValue.shortValue;
}
- (void)setCachePolicy:(RFAPIDefineCachePolicy)cachePolicy {
    self.cachePolicyValue = @(cachePolicy);
}

- (NSTimeInterval)expire {
    return self.cacheExpireValue.doubleValue;
}
- (void)setExpire:(NSTimeInterval)expire {
    self.cacheExpireValue = @(expire);
}

- (RFAPIDefineOfflinePolicy)offlinePolicy {
    return self.offlinePolicyValue.shortValue;
}
- (void)setOfflinePolicy:(RFAPIDefineOfflinePolicy)offlinePolicy {
    self.offlinePolicyValue = @(offlinePolicy);
}

- (RFAPIDefineResponseExpectType)responseExpectType {
    return self.responseExpectTypeValue.shortValue;
}
- (void)setResponseExpectType:(RFAPIDefineResponseExpectType)responseExpectType {
    self.responseExpectTypeValue = @(responseExpectType);
}

- (BOOL)responseAcceptNull {
    return self.responseAcceptNullValue.boolValue;
}
- (void)setResponseAcceptNull:(BOOL)responseAcceptNull {
    self.responseAcceptNullValue = @(responseAcceptNull);
}

#pragma mark -

- (RFAPIDefine *)newDefineMergedDefault:(RFAPIDefine *)defaultDefine {
    RFAPIDefine *ret = defaultDefine.copy;
#define _transf(INDEX, CONTEXT, PROPERTY) \
    if (self.PROPERTY) ret.PROPERTY = self.PROPERTY;

#define _transf_properties(...) \
    metamacro_foreach_cxt(_transf, , , __VA_ARGS__)

    _transf_properties(name,
                       baseURL,
                       pathPrefix,
                       path,
                       method,
                       HTTPRequestHeaders,
                       defaultParameters,
                       needsAuthorizationValue,
                       requestSerializerClass,
                       userInfo,
                       notes)
    _transf_properties(responseSerializerClass,
                       responseExpectTypeValue,
                       responseAcceptNullValue,
                       responseClass)
    _transf_properties(cachePolicyValue,
                       cacheExpireValue,
                       offlinePolicyValue)
    return ret;
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
    self.needsAuthorizationValue = [decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, needsAuthorization)];
    self.requestSerializerClass = NSClassFromString((id)[decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, requestSerializerClass)]);
    self.cachePolicyValue = [decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, cachePolicy)];
    self.cacheExpireValue = [decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, expire)];
    self.offlinePolicyValue = [decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, offlinePolicy)];
    self.responseSerializerClass = NSClassFromString((id)[decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, responseSerializerClass)]);
    self.responseExpectTypeValue = [decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, responseExpectType)];
    self.responseAcceptNullValue = [decoder decodeObjectOfClass:[NSNumber class] forKey:@keypath(self, responseExpectType)];
    self.responseClass = [decoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, responseClass)];
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
    [aCoder encodeObject:self.needsAuthorizationValue forKey:@keypath(self, needsAuthorization)];
    [aCoder encodeObject:self.cachePolicyValue forKey:@keypath(self, cachePolicy)];
    [aCoder encodeObject:self.cacheExpireValue forKey:@keypath(self, expire)];
    [aCoder encodeObject:self.offlinePolicyValue forKey:@keypath(self, offlinePolicy)];
    [aCoder encodeObject:self.responseExpectTypeValue forKey:@keypath(self, responseExpectType)];
    [aCoder encodeObject:self.responseClass forKey:@keypath(self, responseClass)];
    [aCoder encodeObject:self.responseAcceptNullValue forKey:@keypath(self, responseAcceptNull)];
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
    clone.needsAuthorizationValue = self.needsAuthorizationValue;
    clone.requestSerializerClass = self.requestSerializerClass;

    clone.cachePolicyValue = self.cachePolicyValue;
    clone.cacheExpireValue = self.cacheExpireValue;
    clone.offlinePolicyValue = self.offlinePolicyValue;

    clone.responseSerializerClass = self.responseSerializerClass;
    clone.responseExpectTypeValue = self.responseExpectTypeValue;
    clone.responseAcceptNullValue = self.responseAcceptNullValue;
    clone.responseClass = self.responseClass;

    clone.userInfo = self.userInfo;
    clone.notes = self.notes;
    
    return clone;
}

@end
