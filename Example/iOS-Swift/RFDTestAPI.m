
#import "RFDTestAPI.h"
#import "AFURLResponseSerialization.h"
#import <RFAPI/RFAPIDefineConfigFile.h>
#import <RFAPI/RFAPIJSONModelTransformer.h>
#import <RFMessageManager/RFSVProgressMessageManager.h>
#import <RFMessageManager/RFNetworkActivityMessage.h>


@implementation RFDTestAPI

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [self.alloc init];
    });
    return sharedInstance;
}

- (void)onInit {
    [super onInit];

    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"TestAPIDefine" ofType:@"plist"];
    NSDictionary *rules = [[NSDictionary alloc] initWithContentsOfFile:configPath];
    RFAPIDefineManager *dm = self.defineManager;
    [dm setDefinesWithRulesInfo:rules];
    dm.defaultResponseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    self.networkActivityIndicatorManager = [RFSVProgressMessageManager new];
    self.modelTransformer = RFAPIJSONModelTransformer.new;
}

@end

#import <objc/runtime.h>

static char UIViewController_APIControl_CateogryProperty;

@implementation UIViewController (APIControl)

- (NSString *)APIGroupIdentifier {
    id value = objc_getAssociatedObject(self, &UIViewController_APIControl_CateogryProperty);
    if (value) return value;
    return NSStringFromClass(self.class);
}

- (void)setAPIGroupIdentifier:(NSString *)APIGroupIdentifier {
    objc_setAssociatedObject(self, &UIViewController_APIControl_CateogryProperty, APIGroupIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
