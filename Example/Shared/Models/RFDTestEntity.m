
#import "RFDTestEntity.h"
#import <RFKit/RFRuntime.h>

@implementation RFDTestEntity

+ (JSONKeyMapper *)keyMapper {
    RFDTestEntity *this;
    return [JSONKeyMapper.alloc initWithModelToJSONDictionary:@{
        @"id": @keypath(this, uid),
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
