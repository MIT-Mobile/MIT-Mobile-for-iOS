#import "MITDiningLinksTableViewController.h"
#import "UIKit+MITAdditions.h"
#import "MITDiningLinks.h"

static NSString *const kMITDiningLinksTableViewControllerCell = @"kMITDiningLinksTableViewControllerCell";

@implementation MITDiningLinksTableViewController

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
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITDiningLinksTableViewControllerCell];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.diningLinks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITDiningLinksTableViewControllerCell forIndexPath:indexPath];
    
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    
    MITDiningLinks *link = self.diningLinks[indexPath.row];
    cell.textLabel.text = link.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningLinks *link = self.diningLinks[indexPath.row];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:link.url]];
}

@end
