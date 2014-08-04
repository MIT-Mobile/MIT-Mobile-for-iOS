#import "MITCalendarSelectionViewController.h"
#import "MITAcademicHolidaysCalendarViewController.h"
#import "MITAcademicCalendarViewController.h"
#import "MITCalendarManager.h"

typedef NS_ENUM(NSInteger, kEventsSection) {
    kEventsSectionRegistrar,
    kEventsSectionEvents
};

typedef NS_ENUM(NSInteger, kEventsCellRow) {
    kEventsCellRowAcademicHolidays,
    kEventsCellRowAcademic
};

typedef NS_ENUM(NSInteger, kCalendarSelectionMode) {
    kCalendarSelectionModeRoot,
    kCalendarSelectionModeSubCategory
};

static NSString *const kMITCalendarCell = @"kMITCalendarCell";

@interface MITCalendarSelectionViewController ()

@property (nonatomic, strong) MITMasterCalendar *masterCalendar;

@property (nonatomic, strong) MITCalendarsCalendar *selectedCalendar;
@property (nonatomic, strong) MITCalendarsCalendar *selectedCategory;

@property (nonatomic) kCalendarSelectionMode mode;

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
    [self setupNavBar];

    self.title = @"Calendars";

    if (self.category) {
        self.mode = kCalendarSelectionModeSubCategory;
        self.title = self.category.name;
        [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
            if (masterCalendar){
                self.masterCalendar = masterCalendar;
                self.selectedCalendar = masterCalendar.eventsCalendar;
                [self.tableView reloadData];
            }
        }];
    } else {
        self.mode = kCalendarSelectionModeRoot;
        [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
            if (masterCalendar){
                self.masterCalendar = masterCalendar;
                self.selectedCalendar = masterCalendar.eventsCalendar;
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)setupNavBar
{
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
    if (self.mode == kCalendarSelectionModeRoot) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kEventsSectionRegistrar && self.mode == kCalendarSelectionModeRoot) {
        return 2;
    } else {
        return (self.mode == kCalendarSelectionModeRoot) ? [self.selectedCalendar.categories count] : [self.category.categories count];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.mode == kCalendarSelectionModeRoot) {
        if (section == kEventsSectionRegistrar) {
            return @"REGISTRAR CALENDARS";
        }
        else {
            return @"EVENTS CALENDAR";
        }
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITCalendarCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kMITCalendarCell];
    }
    
    if (self.mode == kCalendarSelectionModeRoot && indexPath.section == kEventsSectionRegistrar) {
       if (indexPath.row == kEventsCellRowAcademicHolidays) {
            cell.textLabel.text = self.masterCalendar.academicHolidaysCalendar.name;
        } else {
            cell.textLabel.text = self.masterCalendar.academicCalendar.name;
        }
    } else {
        MITCalendarsCalendar *category = (self.mode == kCalendarSelectionModeRoot) ? self.selectedCalendar.categories[indexPath.row] : self.category.categories[indexPath.row];
        cell.textLabel.text = category.name;
        
        cell.accessoryType = [category.categories count] > 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.mode == kCalendarSelectionModeRoot && indexPath.section == kEventsSectionRegistrar) {
        if (indexPath.row == kEventsCellRowAcademicHolidays) {
            [self showAcademicHolidaysCalendar];
        } else {
            [self showAcademicCalendar];
        }
    } else {
        [self selectCalendarAtIndexPath:indexPath];
    }
}

- (void)showAcademicHolidaysCalendar
{
    MITAcademicHolidaysCalendarViewController *holidaysVC = [[MITAcademicHolidaysCalendarViewController alloc] init];
    [self.navigationController pushViewController:holidaysVC animated:YES];
}

- (void)showAcademicCalendar
{
    MITAcademicCalendarViewController *academicVC = [[MITAcademicCalendarViewController alloc] init];
    [self.navigationController pushViewController:academicVC animated:YES];
}

- (void)selectCalendarAtIndexPath:(NSIndexPath *)indexPath
{
    MITCalendarsCalendar *selectedCategory = (self.mode == kCalendarSelectionModeRoot) ? self.selectedCalendar.categories[indexPath.row] : self.category.categories[indexPath.row];
    
    if (selectedCategory.hasSubCategories) {
        [self showSubCategory:selectedCategory];
    }
    else {
        [self unselectAllCells];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedCategory = selectedCategory;
    }
}

- (void)showSubCategory:(MITCalendarsCalendar *)subCategory
{
    MITCalendarSelectionViewController *subCategoryVC = [[MITCalendarSelectionViewController alloc] initWithNibName:nil bundle:nil];
    subCategoryVC.category = subCategory;
    subCategoryVC.delegate = self;
    [self.navigationController pushViewController:subCategoryVC animated:YES];
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

- (void)calendarSelectionViewController:(MITCalendarSelectionViewController *)viewController
                      didSelectCalendar:(MITCalendarsCalendar *)calendar
                               category:(MITCalendarsCalendar *)category
{
    // This will eventually chain back up to the presenting view controller
    [self.delegate calendarSelectionViewController:viewController didSelectCalendar:calendar category:category];
}

@end
