#import "MITAcademicCalendarViewController.h"
#import "MITCalendarManager.h"
#import "MITCalendarWebservices.h"
#import "MITAcademicCalendarCell.h"
#import "MITCalendarEventDateGroupedDataSource.h"
#import "Foundation+MITAdditions.h"

static NSString *const kMITAcademicCalendarCell = @"MITAcademicCalendarCell";

@interface MITAcademicCalendarViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) MITCalendarsCalendar *academicCalendar;

@property (nonatomic, strong) MITCalendarEventDateGroupedDataSource *eventsDataSource;

@end

@implementation MITAcademicCalendarViewController

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
    [self setupTableView];
    
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        if (masterCalendar) {
            self.academicCalendar = masterCalendar.academicCalendar;
            self.title = self.academicCalendar.name;
            [self loadEvents];
        }
        else {
            NSLog(@"Error fetching calendar: %@", error);
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self scrollToToday];
}

- (void)loadEvents
{
    [MITCalendarWebservices getEventsForCalendar:self.academicCalendar
                                      completion:^(NSArray *events, NSError *error) {
        self.activityIndicator.hidden = YES;
        if (events) {
            self.eventsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:events];
            [self.tableView reloadData];
            [self scrollToToday];
        }
        else {
            NSLog(@"Error fetching events: %@", error);
        }
    }];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITAcademicCalendarCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITAcademicCalendarCell];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return  [[self.eventsDataSource allSections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDate *date = [self.eventsDataSource dateForSection:section];
    return  [[self.eventsDataSource eventsForDate:date] count];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.eventsDataSource headerForSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITAcademicCalendarCell heightForEvent:[self.eventsDataSource eventForIndexPath:indexPath] tableViewWidth:self.tableView.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITAcademicCalendarCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITAcademicCalendarCell forIndexPath:indexPath];
    
    MITCalendarsEvent *event = [self.eventsDataSource eventForIndexPath:indexPath];
    
    [cell setEvent:event];
    
    return cell;
}

- (void)scrollToToday
{
    [self scrollToDate:[NSDate date]];
}

- (void)scrollToDate:(NSDate *)date
{
    if (self.eventsDataSource.events.count > 0) {
        NSInteger section = [self.eventsDataSource sectionBeginningAtDate:date];
        self.currentlyDisplayedDate = [self.eventsDataSource dateForSection:section];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

@end
