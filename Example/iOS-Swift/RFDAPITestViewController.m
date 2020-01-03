
#import "RFDAPITestViewController.h"
#import "RFDTestAPI.h"

@interface RFDAPITestViewController ()
@property (nonatomic, strong) NSArray<RFDAPITestRequestObject *> *items;
@end

@implementation RFDAPITestViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    RFDAPITestRequestObject *r1 = [RFDAPITestRequestObject new];
    r1.title = @"Null";
    r1.APIName = @"NullTest";
    r1.message = @"Request: Null";

    RFDAPITestRequestObject *r2 = [RFDAPITestRequestObject new];
    r2.title = @"An object";
    r2.APIName = @"ObjSample";
    r2.message = @"";

    RFDAPITestRequestObject *r3 = [RFDAPITestRequestObject new];
    r3.title = @"Objects";
    r3.APIName = @"ObjArraySample";
    r3.message = @"Loadding...";
    r3.modal = YES;

    RFDAPITestRequestObject *r4 = [RFDAPITestRequestObject new];
    r4.title = @"Empty object";
    r4.APIName = @"ObjEmpty";
    // r4 no progress
    
    RFDAPITestRequestObject *r5 = [RFDAPITestRequestObject new];
    r5.title = @"Fail request";
    r5.APIName = @"NotFound";

    self.items = @[ r1, r2, r3, r4, r5 ];
}

#pragma mark - List

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RFDAPITestRequestObject *requestDefine = self.items[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = requestDefine.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RFDAPITestRequestObject *request = self.items[indexPath.row];
    @weakify(self)
    [RFDTestAPI.sharedInstance requestWithName:request.APIName context:^(__kindof RFAPIRequestConext *c) {
        c.loadMessage = request.message;
        c.loadMessageShownModal = request.modal;
        c.success = ^(id<RFAPITask>  _Nonnull task, id  _Nullable responseObject) {
            @strongify(self)
            [self displayResponse:responseObject error:nil];
        };
        c.failure = ^(id<RFAPITask>  _Nullable task, NSError * _Nonnull error) {
            @strongify(self)
            [self displayResponse:nil error:error];
        };
    }];
}

- (void)displayResponse:(id)responseObject error:(NSError *)error {
    if (error) {
        self.responseTextView.text = [NSString stringWithFormat:@"%@", error];
        self.responseTextView.textColor = [UIColor redColor];
        return;
    }
    self.responseTextView.text = [NSString stringWithFormat:@"%@", responseObject];
    self.responseTextView.textColor = [UIColor darkTextColor];
}

@end


@implementation RFDAPITestRequestObject
@end
