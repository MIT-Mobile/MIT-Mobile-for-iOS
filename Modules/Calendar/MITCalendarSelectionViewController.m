#import "MITCalendarSelectionViewController.h"
#import "EventCategory.h"

static NSString *const kMITCalendarCell = @"kMITCalendarCell";

@interface MITCalendarSelectionViewController ()

@end

@implementation MITCalendarSelectionViewController

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
    return [self.categories count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITCalendarCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITCalendarCell];
    }
    
    EventCategory *category = self.categories[indexPath.row];
	if (self.navigationController.viewControllers.count > 1 && !category.parentCategory) {
		cell.textLabel.text = [NSString stringWithFormat:@"All %@", category.title];
	} else {
		cell.textLabel.text = category.title;
	}
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;

}




@end
