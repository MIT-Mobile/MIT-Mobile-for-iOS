#import "MITShuttleResourceViewController.h"
#import "MITShuttleResourceData.h"
#import "UIKit+MITAdditions.h"

static NSString * const kMITShuttleResourcePhoneNumberCellIdentifier = @"MITShuttleResourcePhoneNumberCell";
static NSString * const kMITShuttleResourceURLCellIdentifier = @"MITShuttleResourceURLCell";

static const CGFloat kContactInformationCellHeight = 60.0;
static const CGFloat kMBTAInformationCellHeight = 45.0;

static const CGSize kPopoverContentSize = {320.0, 348.0};

typedef NS_ENUM(NSUInteger, MITShuttleResourceSection) {
    MITShuttleResourceSectionContactInformation,
    MITShuttleResourceSectionMBTAInformation
};

@interface MITShuttleResourceViewController ()

@property (nonatomic, strong) MITShuttleResourceData *resourceData;

@end

@implementation MITShuttleResourceViewController

#pragma mark - Init

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.resourceData = [[MITShuttleResourceData alloc] init];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Resources";
    // Must set explicitly for weird navController in popover issue
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.scrollEnabled = NO;
    self.tableView.sectionFooterHeight = 0.0;
    self.contentSizeForViewInPopover = kPopoverContentSize;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kResourceSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleResourceSectionContactInformation:
            return [self.resourceData.contactInformation count];
        case MITShuttleResourceSectionMBTAInformation:
            return [self.resourceData.mbtaInformation count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITShuttleResourceSectionContactInformation:
            return [self tableView:tableView phoneNumberCellForRowAtIndexPath:indexPath];
        case MITShuttleResourceSectionMBTAInformation:
            return [self tableView:tableView URLCellForRowAtIndexPath:indexPath];
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView phoneNumberCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleResourcePhoneNumberCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITShuttleResourcePhoneNumberCellIdentifier];
    }
    NSDictionary *resource = self.resourceData.contactInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
    cell.detailTextLabel.text = resource[kResourceFormattedPhoneNumberKey];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
    cell.detailTextLabel.textColor = [UIColor mit_greyTextColor];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView URLCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITShuttleResourceURLCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITShuttleResourceURLCellIdentifier];
    }
    NSDictionary *resource = self.resourceData.mbtaInformation[indexPath.row];
    cell.textLabel.text = resource[kResourceDescriptionKey];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case MITShuttleResourceSectionContactInformation:
            [self phoneNumberResourceSelected:self.resourceData.contactInformation[indexPath.row]];
            break;
        case MITShuttleResourceSectionMBTAInformation:
            [self urlResourceSelected:self.resourceData.mbtaInformation[indexPath.row]];
            break;
        default:
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case MITShuttleResourceSectionContactInformation:
            return [kContactInformationHeaderTitle uppercaseString];
        case MITShuttleResourceSectionMBTAInformation:
            return [kMBTAInformationHeaderTitle uppercaseString];
        default:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case MITShuttleResourceSectionContactInformation:
            return kContactInformationCellHeight;
        case MITShuttleResourceSectionMBTAInformation:
            return kMBTAInformationCellHeight;
        default:
            return CGFLOAT_MIN;
    }
}

#pragma mark - UITableViewDelegate Helpers

- (void)phoneNumberResourceSelected:(NSDictionary *)resource
{
    NSString *phoneNumber = resource[kResourcePhoneNumberKey];
    NSURL *phoneNumberURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
    if ([[UIApplication sharedApplication] canOpenURL:phoneNumberURL]) {
        [[UIApplication sharedApplication] openURL:phoneNumberURL];
    }
}

- (void)urlResourceSelected:(NSDictionary *)resource
{
    NSString *urlString = resource[kResourceURLKey];
    NSURL *url = [NSURL URLWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
