#import "MITEventDetailViewController.h"
#import "MITEventDetailCell.h"
#import "MITCalendarEvent.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"
#import "MITEventHeaderCell.h"

static NSString * const kMITEventHeaderCellNibName = @"MITEventHeaderCell";
static NSString * const kMITEventHeaderCellIdentifier = @"kMITEventHeaderIdentifier";

static NSString * const kMITEventDetailCellNibName = @"MITEventDetailCell";
static NSString * const kMITEventDetailCellIdentifier = @"kMITEventDetailIdentifier";

static NSString * const kMITEventWebviewCellNibName = @"MITWebviewCell";
static NSString * const kMITEventWebviewCellIdentifier = @"kMITEventWebviewIdentifier";

static NSInteger const kMITEventNameSection = 0;
static NSInteger const kMITEventDetailsSection = 1;

typedef NS_ENUM(NSInteger, MITEventDetailRowType) {
    MITEventDetailRowTypeTime,
    MITEventDetailRowTypeLocation,
    MITEventDetailRowTypePhone,
    MITEventDetailRowTypeWebsite,
    MITEventDetailRowTypeDescription
};

@interface MITEventDetailViewController ()

@property (nonatomic, strong) NSArray *rowTypes;
@property (nonatomic) BOOL isLoadingEventDetails;

@end

@implementation MITEventDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Public Methods

- (void)setEvent:(MITCalendarEvent *)event
{
    if (![self.event isEqual:event]) {
        _event = event;
        
        if ([self.event hasMoreDetails] && [self.event.summary length] == 0) {
            [self requestEventDetails];
        }
    }
}

#pragma mark - Private Methods

- (void)refreshEventRows
{
    NSMutableArray *rowTypes = [NSMutableArray array];
    
	if (self.event.start) {
		[rowTypes addObject:@(MITEventDetailRowTypeTime)];
	}
    
	if (self.event.shortloc || self.event.location) {
		[rowTypes addObject:@(MITEventDetailRowTypeLocation)];
	}
    
	if (self.event.phone) {
		[rowTypes addObject:@(MITEventDetailRowTypePhone)];
	}
    
	if (self.event.url) {
		[rowTypes addObject:@(MITEventDetailRowTypeWebsite)];
	}
    
	if (self.event.summary.length) {
		[rowTypes addObject:@(MITEventDetailRowTypeDescription)];
	}
    
    self.rowTypes = rowTypes;
    [self.tableView reloadData];
}

- (void)requestEventDetails
{
    if (self.isLoadingEventDetails) {
        return;
    }
    
    self.isLoadingEventDetails = YES;
    
    NSURLRequest *request = [NSURLRequest requestForModule:CalendarTag command:@"detail" parameters:@{@"id":[self.event.eventID stringValue]}];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *jsonResult) {
        self.isLoadingEventDetails = NO;
        
        if ([jsonResult isKindOfClass:[NSDictionary class]]) {
            if ([jsonResult[@"id"] integerValue] == [self.event.eventID integerValue]) {
                [self.event updateWithDict:jsonResult];
                [self refreshEventRows];
            }
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        self.isLoadingEventDetails = NO;
        DDLogVerbose(@"Calendar 'detail' request failed: %@",[error localizedDescription]);
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

#pragma mark - Custom Cells

- (CGFloat)heightForDetailCellOfType:(MITEventDetailRowType)type
{
    static MITEventDetailCell *detailCell;
    if (!detailCell) {
        detailCell = [[NSBundle mainBundle] loadNibNamed:kMITEventDetailCellNibName owner:self options:nil][0];
    }
    
    switch (type) {
        case MITEventDetailRowTypeTime: {
            [detailCell setTitle:@"time"];
            NSString *timeDetailString = [self.event dateStringWithDateStyle:NSDateFormatterFullStyle
                                                                   timeStyle:NSDateFormatterShortStyle
                                                                   separator:@"\n"];
            [detailCell setDetailText:timeDetailString];
            break;
        }
        case MITEventDetailRowTypeLocation: {
            [detailCell setTitle:@"location"];
            NSString *locationDetailString = (self.event.location != nil) ? self.event.location : self.event.shortloc;
            [detailCell setDetailText:locationDetailString];
            break;
        }
        case MITEventDetailRowTypePhone: {
            [detailCell setTitle:@"phone"];
            [detailCell setDetailText:self.event.phone];
            break;
        }
        case MITEventDetailRowTypeWebsite: {
            [detailCell setTitle:@"web site"];
            [detailCell setDetailText:self.event.url];
            break;
        }
        case MITEventDetailRowTypeDescription: {
            // return webview cell height
            break;
        }
        default: {
            return 0;
            break;
        }
    }
    
    
    [detailCell setNeedsUpdateConstraints];
    [detailCell updateConstraintsIfNeeded];
    detailCell.bounds = CGRectMake(0, 0, self.tableView.bounds.size.width, detailCell.bounds.size.height);
    [detailCell setNeedsLayout];
    [detailCell layoutIfNeeded];
    
    CGFloat height = [detailCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height;   // add pt for cell separator;
    
    return height;
}

- (CGFloat)heightForTitleCell
{
    static MITEventHeaderCell *headerCell;
    if (!headerCell) {
        headerCell = [[NSBundle mainBundle] loadNibNamed:kMITEventHeaderCellNibName owner:self options:nil][0];
    }
    
    [headerCell setEventTitle:self.event.title isPartOfSeries:NO];
    
    [headerCell setNeedsUpdateConstraints];
    [headerCell updateConstraintsIfNeeded];
    headerCell.bounds = CGRectMake(0, 0, self.tableView.bounds.size.width, headerCell.bounds.size.height);
    [headerCell setNeedsLayout];
    [headerCell layoutIfNeeded];
    
    CGFloat height = [headerCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    ++height;   // add pt for cell separator;
    
    return height;
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITEventNameSection: {
            return [self heightForTitleCell];
        }
        case kMITEventDetailsSection: {
            MITEventDetailRowType rowType = [self.rowTypes[indexPath.row] integerValue];
            return [self heightForDetailCellOfType:rowType];
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    switch (indexPath.section) {
//        case kMITMapPlaceBottomButtonsSection: {
//            switch (indexPath.row) {
//                case kMITMapPlaceBottomButtonAddToBookmarksRow: {
//                    [self addOrRemoveBookmark];
//                    break;
//                }
//                case kMITMapPlaceBottomButtonOpenInMapsRow: {
//                    [self openInMaps];
//                    break;
//                }
//                case kMITMapPlaceBottomButtonOpenInGoogleMapsRow: {
//                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
//                        [self openInGoogleMaps];
//                    }
//                    break;
//                }
//                default: {
//                    break;
//                }
//            }
//        }
//        default: {
//            return;
//        }
//    }
//}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kMITEventNameSection: {
            return 1;
            break;
        }
        case kMITEventDetailsSection: {
            return self.rowTypes.count;
            break;
        }
        default: {
            return 0;
            break;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case kMITEventNameSection: {
            // Return the title cell
        }
        case kMITEventDetailsSection: {
            MITEventDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITEventDetailCellIdentifier];
            
            NSInteger rowType = [self.rowTypes[indexPath.row] integerValue];
            
            switch (rowType) {
                case MITEventDetailRowTypeTime: {
                    //
                    break;
                }
                case MITEventDetailRowTypeLocation: {
                    
                    break;
                }
                case MITEventDetailRowTypePhone: {
                    //
                    break;
                }
                case MITEventDetailRowTypeWebsite: {
                    //
                    break;
                }
                case MITEventDetailRowTypeDescription: {
                    //
                    break;
                }
                default: {
                    //
                    break;
                }
            }
            
            return cell;
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    switch (section) {
//        case kMITMapPlaceBottomButtonsSection: {
//            return 10;
//        }
//        default: {
//            return 0;
//        }
//    }
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    switch (section) {
//        case kMITMapPlaceBottomButtonsSection: {
//            return 10;
//        }
//        default: {
//            return 0;
//        }
//    }
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    switch (section) {
//        case kMITMapPlaceBottomButtonsSection: {
//            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];
//        }
//        default: {
//            return [UIView new];
//        }
//    }
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    switch (section) {
//        case kMITMapPlaceBottomButtonsSection: {
//            return [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];
//        }
//        default: {
//            return [UIView new];
//        }
//    }
//}

@end
