#import "MITCalendarSelectionHomeViewController.h"
#import "MITCalendarManager.h"

static NSString *const kMITCalendarCell = @"kMITCalendarCell";

@interface MITCalendarSelectionHomeViewController ()

@property (nonatomic, strong) MITCalendarsCalendar *selectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *selectedCategory;

@end

@implementation MITCalendarSelectionHomeViewController

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
    [self setupNavBar];

}

- (void)setupNavBar
{
    self.title = @"Calendars";
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    else {
        return [[MITCalendarManager sharedManager].eventsCalendar.categories count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"REGISTRAR CALENDARS";
    }
    else {
        return @"EVENTS CALENDAR";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITCalendarCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITCalendarCell];
    }
    
    if (indexPath.section == 0){
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Holidays";
        }
        else {
            cell.textLabel.text = @"Academic Calendar";
        }
    }
    if (indexPath.section == 1) {
        MITCalendarsCalendar *category = [MITCalendarManager sharedManager].eventsCalendar.categories[indexPath.row];
		cell.textLabel.text = category.name;
        
        cell.accessoryType = [category.categories count] > 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	}
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self unselectAllCells];
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section == 1) {
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedCalendar = [MITCalendarManager sharedManager].eventsCalendar;
        self.selectedCategory = [MITCalendarManager sharedManager].eventsCalendar.categories[indexPath.row];
    }
}

- (void)showSubCategory:(MITCalendarsCalendar *)subCategory
{
    
}

- (void)unselectAllCells
{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)doneButtonPressed:(id)sender
{
    [self.delegate calendarSelectionViewController:self didSelectCalendar:self.selectedCalendar category:self.selectedCategory];
}

@end
