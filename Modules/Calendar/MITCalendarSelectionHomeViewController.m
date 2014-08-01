#import "MITCalendarSelectionHomeViewController.h"
#import "MITCalendarManager.h"

typedef NS_ENUM(NSInteger, kEventsSection) {
    kEventsSectionRegistrar,
    kEventsSectionEvents
};

typedef NS_ENUM(NSInteger, kEventsCellRow) {
    kEventsCellRowAcademicHolidays,
    kEventsCellRowAcademic
};

static NSString *const kMITCalendarCell = @"kMITCalendarCell";

@interface MITCalendarSelectionHomeViewController ()

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

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

    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar){
            self.masterCalendar = masterCalendar;
            [self.tableView reloadData];
        }
    }];
    
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
        return [self.masterCalendar.eventsCalendar.categories count];
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
    
    switch (indexPath.section) {
        case kEventsSectionRegistrar:
            
            switch (indexPath.row) {
                case kEventsCellRowAcademicHolidays:
                    cell.textLabel.text = @"Holidays";
                    break;
                case kEventsCellRowAcademic:
                    cell.textLabel.text = @"Academic Calendar";
                    break;
                default:
                    break;
            }
            break;
            
        case kEventsSectionEvents:
        {
            MITCalendarsCalendar *category = self.masterCalendar.eventsCalendar.categories[indexPath.row];
            cell.textLabel.text = category.name;
            
            cell.accessoryType = [category.categories count] > 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        }
        default:
            break;
    }
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self unselectAllCells];
    
    switch (indexPath.section) {
        case kEventsSectionRegistrar:
            switch (indexPath.row) {
                case kEventsCellRowAcademicHolidays:
                    [self selectAcademicHolidaysCalendar];
                    break;
                
                case kEventsCellRowAcademic:
                    [self selectAcademicCalendar];
                    
                default:
                    break;
            }
            break;
            
        case kEventsSectionEvents:
        {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            self.selectedCalendar = self.masterCalendar.eventsCalendar;
            self.selectedCategory = self.masterCalendar.eventsCalendar.categories[indexPath.row];
        }
            
            break;
        default:
            break;
    }
 
}

- (void)selectAcademicHolidaysCalendar
{
    self.selectedCalendar = self.masterCalendar.academicHolidaysCalendar;
    self.selectedCategory = nil;
}

- (void)selectAcademicCalendar
{
    self.selectedCalendar = self.masterCalendar.academicCalendar;
    self.selectedCategory = nil;
}

- (void)selectEventsCalendarAtIndexPath:(NSIndexPath *)indexPath
{
    //MITCalendarsCalendar *selectedCategory = sel
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
