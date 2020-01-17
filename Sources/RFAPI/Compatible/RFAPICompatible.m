
#import "RFAPICompatible.h"

@implementation RFAPI (V1Compatible)

- (id<RFAPITask>)requestWithName:(NSString *)APIName parameters:(NSDictionary *)parameters controlInfo:(RFAPIRequestConext *)controlInfo success:(void (^)(id<RFAPITask> _Nullable, id _Nullable))success failure:(void (^)(id<RFAPITask> _Nullable, NSError * _Nonnull))failure completion:(void (^)(id<RFAPITask> _Nullable))completion {
    return [self requestWithName:APIName context:^(RFAPIRequestConext *c) {
        c.parameters = parameters;
        if (controlInfo) {
            c.activityMessage = controlInfo.activityMessage;
            c.identifier = controlInfo.identifier;
            c.groupIdentifier = controlInfo.groupIdentifier;
            c.requestCustomization = controlInfo.requestCustomization;
        }
        c.success = success;
        c.failure = failure;
        if (completion) {
            c.finished = ^(id<RFAPITask>  _Nullable task, BOOL success) {
                completion(task);
            };
        }
    }];
}

@end


#import <RFMessageManager/RFMessageManager+RFDisplay.h>

@implementation RFAPIControl (V1Compatible)

- (id)initWithIdentifier:(NSString *)identifier loadingMessage:(NSString *)message {
    self = [super init];
    self.identifier = identifier;
    RFNetworkActivityMessage *m = [[RFNetworkActivityMessage alloc] initWithIdentifier:identifier message:message status:RFNetworkActivityStatusLoading];
    self.activityMessage = m;
    return self;
}

@end
