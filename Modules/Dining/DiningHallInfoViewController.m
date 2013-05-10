
#import "DiningHallInfoViewController.h"
#import "DiningHallDetailHeaderView.h"
#import "VenueLocation.h"

#import "UIKit+MITAdditions.h"
#import "Foundation+MITAdditions.h"

@interface DiningHallInfoViewController ()

@property (nonatomic, assign) NSInteger locationSectionIndex;
@property (nonatomic, assign) NSInteger paymentSectionIndex;
@property (nonatomic, assign) NSInteger scheduleSectionIndex;

@end

@implementation DiningHallInfoViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    DiningHallDetailHeaderView *headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    headerView.titleLabel.text = self.venue.name;
    
    NSDictionary *timeData = self.hallStatus;
    if ([timeData[@"isOpen"] boolValue]) {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#008800"];
    } else {
        headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#bb0000"];
    }
    headerView.timeLabel.text = timeData[@"text"];
    self.tableView.tableHeaderView = headerView;
    
    _locationSectionIndex   = 0;
    _paymentSectionIndex    = 1;
    _scheduleSectionIndex   = 2;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:12];
    cell.textLabel.textColor = [UIColor darkTextColor];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:13];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == _locationSectionIndex) {
        cell.textLabel.text = @"location";
        cell.detailTextLabel.text = self.venue.location.displayDescription;
        cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewMap];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else if (indexPath.section == _paymentSectionIndex) {
        cell.textLabel.text = @"payment";
        cell.detailTextLabel.text = [[self.venue.paymentMethods allObjects] componentsJoinedByString:@", "];
        
    } else {
        // schedule
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == _locationSectionIndex) {
        
    }
}

@end
