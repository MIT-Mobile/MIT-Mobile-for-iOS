//
//  DiningHallDetailViewController.m
//  MIT Mobile
//
//  Created by Austin Emmons on 4/2/13.
//
//

#import "DiningHallMenuViewController.h"
#import "DiningMenuCompareViewController.h"
#import "DiningHallMenuHeaderView.h"

@interface DiningHallMenuViewController ()

@end

@implementation DiningHallMenuViewController

- (NSArray *) debugData
{
    NSDictionary *item1 = @{@"type": @"kosher", @"title" : @"kosher dinner", @"subtitle" : @"lemon chicken with pasta, green beans, yellow squash, tossed salad, fruit salad, stir fried tofu with spicy orange sauce", @"filters" : @"1, 2, 3, 4"};
    NSDictionary *item2 = @{@"type": @"whirl wind", @"title" : @"thai curry", @"subtitle" : @"a spicy green thai curry sauce with snow peas, shiitake mushrooms, onions, red peppers, broccoli, and scallions", @"filters" : @"3, 4"};
    NSDictionary *item3 = @{@"type": @"deli +", @"title" : @"baked potato bar", @"subtitle" : @"butter, sour cream, cheese sauce, veggie chili, chili, jalapenos, broccoli, and more", @"filters" : @"1, 3, 4"};
    
    return @[item1, item2, item3];
}

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
    
    DiningHallMenuHeaderView *headerView = [[DiningHallMenuHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 87)];
    self.tableView.tableHeaderView = headerView;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeLeft) {
        return YES;
    }
    return NO;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    DiningMenuCompareViewController *vc = [[DiningMenuCompareViewController alloc] init];
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:vc animated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self debugData] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *itemDict = [self debugData][indexPath.row];
    cell.textLabel.text = itemDict[@"title"];
    cell.detailTextLabel.text = itemDict[@"subtitle"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
