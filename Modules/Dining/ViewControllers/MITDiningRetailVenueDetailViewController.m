
#import "MITDiningRetailVenueDetailViewController.h"
#import "MITDiningRetailVenue.h"
#import "MITDiningRetailDay.h"

#import "DiningHallDetailHeaderView.h"
#import "UIKit+MITAdditions.h"

@interface MITDiningRetailVenueDetailViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) DiningHallDetailHeaderView *headerView;
@end

@implementation MITDiningRetailVenueDetailViewController

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
    // Do any additional setup after loading the view.
    self.title = self.retailVenue.shortName;
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupHeaderView];
}

- (void)setupHeaderView
{
    self.headerView = [[DiningHallDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    [self.headerView.iconView setImageWithURL:[NSURL URLWithString:self.retailVenue.iconURL]];
    self.headerView.titleLabel.text = self.retailVenue.name;
    self.headerView.infoButton.hidden = YES;
    
    /*
    if (self.retailVenue.isOpenNow) {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#009900"];
    } else {
        self.headerView.timeLabel.textColor = [UIColor colorWithHexString:@"#d20000"];
    }
    
    NSDate *date = [NSDate date];
    RetailDay *yesterday = [self.venue dayForDate:[date dayBefore]];
    RetailDay *currentDay = [self.venue dayForDate:date];
    if ([yesterday.endTime compare:date] == NSOrderedDescending) {
        // yesterday's hours end today and are still valid
        self.headerView.timeLabel.text = [yesterday statusStringRelativeToDate:date];
    } else {
        self.headerView.timeLabel.text = [currentDay statusStringRelativeToDate:date];
    }
     */
    self.headerView.shouldIncludeSeparator = NO;
    self.tableView.tableHeaderView = self.headerView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
