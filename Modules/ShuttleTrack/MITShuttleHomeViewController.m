#import "MITShuttleHomeViewController.h"
#import "MITShuttleRouteCell.h"
#import "MITShuttleStopCell.h"

#import "UIKit+MITAdditions.h"

static NSString * const kMITShuttleRouteCellNibName = @"MITShuttleRouteCell";
static NSString * const kMITShuttleRouteCellIdentifier = @"MITShuttleRouteCell";

static NSString * const kMITShuttleStopCellNibName = @"MITShuttleStopCell";
static NSString * const kMITShuttleStopCellIdentifier = @"MITShuttleStopCell";

static NSString * const kMITShuttlePhoneNumberCellIdentifier = @"MITPhoneNumberCell";
static NSString * const kMITShuttleURLCellIdentifier = @"MITURLCell";

static NSString * const kContactInformationHeaderTitle = @"Contact Information";
static NSString * const kMBTAInformationHeaderTitle = @"MBTA Information";

static const NSInteger kRouteCellRow = 0;

static const NSInteger kResourceSectionCount = 2;

static const CGFloat kRouteSectionHeaderHeight = CGFLOAT_MIN;
static const CGFloat kRouteSectionFooterHeight = CGFLOAT_MIN;

static const CGFloat kContactInformationCellHeight = 60.0;

typedef enum {
    MITShuttleResourceSectionContactInformation = 0,
    MITShuttleResourceSectionMBTAInformation = 1
} MITShuttleResourceSection;

@interface MITShuttleHomeViewController ()

@property (weak, nonatomic) IBOutlet UITableView *routesTableView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationStatusLabel;

@property (copy, nonatomic) NSArray *routes;

@end

@implementation MITShuttleHomeViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Shuttles";
        self.routes = @[@0, @1, @2, @3];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupRoutesTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup

- (void)setupRoutesTableView
{
    [self.routesTableView registerNib:[UINib nibWithNibName:kMITShuttleRouteCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleRouteCellIdentifier];
    [self.routesTableView registerNib:[UINib nibWithNibName:kMITShuttleStopCellNibName bundle:nil] forCellReuseIdentifier:kMITShuttleStopCellIdentifier];
}

#pragma mark - Resource Section Helpers

- (NSInteger)sectionIndexForResourceSection:(MITShuttleResourceSection)section
{
    return [self.routes count] + section;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.routes count] + kResourceSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return 2;
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return 3;
    } else {
#warning TODO: data source - return 1 for route with no stops, or 3 for route with two nearest stops
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return [self tableView:tableView phoneNumberCellForRowAtIndexPath:indexPath];
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return [self tableView:tableView URLCellForRowAtIndexPath:indexPath];
    } else {
        switch (indexPath.row) {
            case kRouteCellRow: {
                return [self tableView:tableView routeCellForRowAtIndexPath:indexPath];
            }
            default: {
                return [self tableView:tableView stopCellForRowAtIndexPath:indexPath];
            }
        }
    }
}

#pragma mark - UITableViewDataSource Helpers

- (UITableViewCell *)tableView:(UITableView *)tableView routeCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleRouteCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleRouteCellIdentifier forIndexPath:indexPath];
#warning TODO: set route item on cell
    [cell setRoute:nil];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView stopCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITShuttleStopCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleStopCellIdentifier forIndexPath:indexPath];
#warning TODO: set stop item on cell
    [cell setStop:nil];
    [cell setCellType:MITShuttleStopCellTypeRouteList];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView phoneNumberCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttlePhoneNumberCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITShuttlePhoneNumberCellIdentifier];
    }
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
#warning TODO: set title and phone number
    cell.textLabel.text = @"Parking Office";
    cell.detailTextLabel.text = @"617.258.6510";
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView URLCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleURLCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITShuttleURLCellIdentifier];
    }
#warning TODO: set title
    cell.textLabel.text = @"Real-time Bus Arrivals";
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return kContactInformationHeaderTitle;
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return kMBTAInformationHeaderTitle;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation] ||
        section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return tableView.sectionHeaderHeight;
    }
    return kRouteSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSInteger lastRouteSection = [self.routes count] - 1;
    if (section < lastRouteSection) {
        return kRouteSectionFooterHeight;
    } else {
        return tableView.sectionFooterHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        return kContactInformationCellHeight;
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        return tableView.rowHeight;
    } else {
        switch (indexPath.row) {
            case kRouteCellRow:
                return [MITShuttleRouteCell cellHeightForRoute:nil];
            default:
                return tableView.rowHeight;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger section = indexPath.section;
    if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionContactInformation]) {
        NSString *phoneNumber;
		NSURL *phoneNumberURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
		if ([[UIApplication sharedApplication] canOpenURL:phoneNumberURL]) {
			[[UIApplication sharedApplication] openURL:phoneNumberURL];
        }
    } else if (section == [self sectionIndexForResourceSection:MITShuttleResourceSectionMBTAInformation]) {
        NSString *urlString;
        NSURL *url = [NSURL URLWithString:urlString];
		if ([[UIApplication sharedApplication] canOpenURL:url]) {
			[[UIApplication sharedApplication] openURL:url];
        }
    } else {
#warning TODO: push route/stop view controller
    }
}

@end
