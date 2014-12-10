#import "MITCalendarSelectionViewController.h"
#import "MITAcademicHolidaysCalendarViewController.h"
#import "MITAcademicCalendarViewController.h"
#import "MITCalendarManager.h"
#import "UIKit+MITAdditions.h"

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

@property (nonatomic) BOOL interfaceIsPad;

@end

@interface MITColoredChevron : UIView

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
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.interfaceIsPad = YES;
    }
    
    
    [self setupNavBar];

    self.title = @"Calendars";

    if (self.category) {
        self.mode = kCalendarSelectionModeSubCategory;
        self.title = self.category.name;
    } else {
        self.mode = kCalendarSelectionModeRoot;
    }
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar){
            self.masterCalendar = masterCalendar;
            self.selectedCalendar = masterCalendar.eventsCalendar;
            for (MITCalendarsCalendar *category in self.category.categories) {
                if ([self pathContainsCategory:category]) {
                    self.selectedCategory = category;
                }
            }
            [self.tableView reloadData];
        }
    }];

}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)setupNavBar
{
    if (!self.interfaceIsPad) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonPressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Delegate/DataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.mode == kCalendarSelectionModeRoot && !self.shouldHideRegistrar) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kEventsSectionRegistrar && self.mode == kCalendarSelectionModeRoot && !self.shouldHideRegistrar) {
        return 2;
    } else {
        return (self.mode == kCalendarSelectionModeRoot) ? [self.masterCalendar.eventsCalendar.categories count] + 1 : [self.category.categories count] + 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.mode == kCalendarSelectionModeRoot && !self.shouldHideRegistrar) {
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (self.mode == kCalendarSelectionModeRoot && indexPath.section == kEventsSectionRegistrar && !self.shouldHideRegistrar) {
        if (indexPath.row == kEventsCellRowAcademicHolidays) {
            cell.textLabel.text = self.masterCalendar.academicHolidaysCalendar.name;
            if (self.interfaceIsPad) {
                cell.accessoryType = [self.selectedCalendar isEqualToCalendar:self.masterCalendar.academicHolidaysCalendar] ?  UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
        } else {
            cell.textLabel.text = self.masterCalendar.academicCalendar.name;
            if (self.interfaceIsPad) {
                cell.accessoryType = [self.selectedCalendar isEqualToCalendar:self.masterCalendar.academicCalendar] ?  UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            }
        }
        
    }
    else if (self.mode == kCalendarSelectionModeRoot && indexPath.row == 0) {
        cell.textLabel.text = @"All Events";
        cell.accessoryType = ([self.selectedCalendar isEqualToCalendar:self.masterCalendar.eventsCalendar]  && self.categoriesPath.count < 1) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if (self.mode == kCalendarSelectionModeSubCategory && indexPath.row == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"All %@", self.category.name];
        cell.accessoryType = ([(MITCalendarsCalendar *)[self.categoriesPath lastObject] isEqualToCalendar:self.category]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        MITCalendarsCalendar *category = (self.mode == kCalendarSelectionModeRoot) ? self.masterCalendar.eventsCalendar.categories[indexPath.row - 1] : self.category.categories[indexPath.row - 1];
        cell.textLabel.text = (self.mode == kCalendarSelectionModeRoot && indexPath.row == 0) ? @"All Events" : category.name;
        [self setAccessoryForCell:cell forCategory:category];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (self.mode) {
        case kCalendarSelectionModeRoot: {
            if (indexPath.section == kEventsSectionRegistrar && !self.shouldHideRegistrar) {
                [self selectRegistrarCalendarAtIndex:indexPath.row];
            } else {
                self.selectedCalendar = self.masterCalendar.eventsCalendar;
                if (indexPath.row == 0) {
                    self.selectedCategory = nil;
                    [self.categoriesPath removeAllObjects];
                    [self.tableView reloadData];
                    if (self.interfaceIsPad) {
                        [self didFinishSelecting];
                    }
                } else {
                    [self selectCalendarAtIndexPath:indexPath];
                }
            }
            break;
        }
        case kCalendarSelectionModeSubCategory: {
            if (indexPath.row == 0) {
                self.selectedCategory = self.category;
                [self addCategoriesToPathUpToCurrentCategory];
                [self.tableView reloadData];
                if (self.interfaceIsPad) {
                    [self didFinishSelecting];
                }
            } else {
                [self selectCalendarAtIndexPath:indexPath];
            }
            break;
        }
    }
}

#pragma mark - TableView Helper Methods

- (void)setAccessoryForCell:(UITableViewCell *)cell forCategory:(MITCalendarsCalendar *)category
{
    cell.accessoryView = nil;
    if (category.categories.count > 0) {
        if ([self pathContainsCategory:category]) {
            cell.accessoryView = [[MITColoredChevron alloc] initWithFrame:CGRectMake(0, 0, 13, 18)];
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    else {
        if ([category isEqualToCalendar:self.selectedCategory] || [self pathContainsCategory:category]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}

- (void)selectRegistrarCalendarAtIndex:(NSInteger)index
{
    if (!self.interfaceIsPad) {
        if (index == kEventsCellRowAcademicHolidays) {
            [self showAcademicHolidaysCalendar];
        } else {
            [self showAcademicCalendar];
        }
    } else {
        if (index == kEventsCellRowAcademicHolidays) {
            self.selectedCalendar = self.masterCalendar.academicHolidaysCalendar;
            self.selectedCategory = nil;
            [self didFinishSelecting];
        } else {
            self.selectedCalendar = self.masterCalendar.academicCalendar;
            self.selectedCategory = nil;
            [self didFinishSelecting];
        }
        [self.tableView reloadData];
    }
}

- (void)selectCalendarAtIndexPath:(NSIndexPath *)indexPath
{
    MITCalendarsCalendar *selectedCategory = (self.mode == kCalendarSelectionModeRoot) ? self.masterCalendar.eventsCalendar.categories[indexPath.row - 1] : self.category.categories[indexPath.row - 1];
    
    if (selectedCategory.hasSubCategories) {
        [self showSubCategory:selectedCategory];
    }
    else {
        [self selectCategory:selectedCategory];
        [self.tableView reloadData];
    }
}

#pragma mark -

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

- (void)selectCategory:(MITCalendarsCalendar *)category
{
    self.selectedCategory = category;
    [self addCategoriesToPathUpToCurrentCategory];
    [self.categoriesPath addObject:self.selectedCategory];
    if (self.interfaceIsPad) {
        [self didFinishSelecting];
    }
}

- (void)addCategoriesToPathUpToCurrentCategory
{
    [self.categoriesPath removeAllObjects];
    for (MITCalendarSelectionViewController *vc in [self.navigationController viewControllers]) {
        if (vc.category) {
            [self.categoriesPath addObject:vc.category];
        }
    }
}

- (void)showSubCategory:(MITCalendarsCalendar *)subCategory
{
    MITCalendarSelectionViewController *subCategoryVC = [[MITCalendarSelectionViewController alloc] initWithNibName:nil bundle:nil];
    subCategoryVC.category = subCategory;
    subCategoryVC.delegate = self;
    subCategoryVC.categoriesPath = self.categoriesPath;
    [self.navigationController pushViewController:subCategoryVC animated:YES];
}

- (void)doneButtonPressed:(id)sender
{
    [self didFinishSelecting];
}

- (void)didFinishSelecting
{
    [self.delegate calendarSelectionViewController:self didSelectCalendar:self.selectedCalendar category:self.selectedCategory];
}

- (void)calendarSelectionViewController:(MITCalendarSelectionViewController *)viewController
                      didSelectCalendar:(MITCalendarsCalendar *)calendar
                               category:(MITCalendarsCalendar *)category
{
    // This will eventually chain back up to the presenting view controller
    [self.delegate calendarSelectionViewController:self didSelectCalendar:calendar category:category];
}

#pragma mark - Selection State Tracking

- (NSMutableArray *)categoriesPath {
    if (!_categoriesPath) {
        _categoriesPath = [[NSMutableArray alloc] init];
    }
    return _categoriesPath;
}

- (BOOL)pathContainsCategory:(MITCalendarsCalendar *)category
{
    for (MITCalendarsCalendar *categoryInPath in self.categoriesPath) {
        if ([category isEqualToCalendar:categoryInPath]) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark -
@implementation MITColoredChevron

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat padding = 4.0;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor mit_tintColor].CGColor);
    CGContextSetLineWidth(context, 3.f);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    
    CGContextMoveToPoint(context, padding, padding);
    CGContextAddLineToPoint(context, self.frame.size.width - padding, self.frame.size.height/2);
    CGContextAddLineToPoint(context, padding, self.frame.size.height - padding);
    
    CGContextStrokePath(context);
}

@end
