#import "MITLibrariesLibraryDetailViewController.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesHoursCell.h"
#import "MITLibrariesTerm.h"
#import "UIKit+MITAdditions.h"
#import "UIKit+MITLibraries.h"
#import "MITTiledMapView.h"

static NSString *const kMITDefaultCell = @"kMITDefaultCell";
static NSString *const kMITHoursCell = @"MITLibrariesHoursCell";

typedef NS_ENUM(NSInteger, MITLibraryDetailCell) {
    MITLibraryDetailCellPhone,
    MITLibraryDetailCellLocation,
    MITLibraryDetailCellHoursToday,
    MITLibraryDetailCellOther
};

@interface MITLibrariesLibraryDetailViewController ()

@property (nonatomic, strong) MITTiledMapView *mapView;

@end

@implementation MITLibrariesLibraryDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.library.name;

    [self setupTableView];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self setupTableHeader];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITHoursCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITHoursCell];
    
    self.tableView.allowsSelection = NO;
}

- (void)setupTableHeader
{
    self.mapView = [[MITTiledMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
    [self.mapView setButtonsHidden:YES animated:NO];
    self.mapView.mapView.showsUserLocation = YES;
    self.mapView.userInteractionEnabled = NO;
    self.tableView.tableHeaderView = self.mapView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3 + self.library.terms.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < MITLibraryDetailCellOther) {
        return 54.0;
    }
    return [MITLibrariesHoursCell heightForContent:[self termForIndexPath:indexPath] tableViewWidth:self.tableView.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case MITLibraryDetailCellPhone:
            return [self phoneNumberCell];
            break;
        case MITLibraryDetailCellLocation:
            return [self locationCell];
            break;
        case MITLibraryDetailCellHoursToday:
            return [self hoursTodayCell];
            break;
        case MITLibraryDetailCellOther:
        default:
            return [self termHoursCellForIndexPath:indexPath];
            break;
    }
}

- (UITableViewCell *)phoneNumberCell
{
    UITableViewCell *cell = [self defaultCell];
    cell.textLabel.text = @"phone";
    cell.detailTextLabel.text = self.library.phoneNumber;
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewPhone];
    return cell;
}

- (UITableViewCell *)locationCell
{
    UITableViewCell *cell = [self defaultCell];
    cell.textLabel.text = @"location";
    cell.detailTextLabel.text = self.library.location;
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
    return cell;
}

- (UITableViewCell *)hoursTodayCell
{
    UITableViewCell *cell = [self defaultCell];
    cell.textLabel.text = @"today's hours";
    cell.detailTextLabel.text = [self.library hoursStringForDate:[NSDate date]];
    cell.accessoryView = nil;
    return cell;
}

- (UITableViewCell *)termHoursCellForIndexPath:(NSIndexPath *)indexPath
{
    MITLibrariesHoursCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITHoursCell forIndexPath:indexPath];
    
    [cell setContent:[self termForIndexPath:indexPath]];
    
    return cell;
}

- (UITableViewCell *)defaultCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITDefaultCell];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITDefaultCell];
        cell.textLabel.textColor = [UIColor mit_tintColor];
        cell.textLabel.font = [UIFont librariesSubtitleStyleFont];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:17.0];
    }
    return cell;
}

- (MITLibrariesTerm *)termForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.row - 3;
    return self.library.terms[index];
}

- (void)dismiss
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
