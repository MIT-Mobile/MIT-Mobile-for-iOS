#import "MITEventsTableViewController.h"
#import "MITCalendarEventCell.h"
#import "MITCalendarsEvent.h"

static NSString *const kMITCalendarEventCell = @"MITCalendarEventCell";

@interface MITEventsTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noResultsFoundLabel;

@property (strong, nonatomic) NSMutableArray *indexesOfHolidayEvents;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@end

@implementation MITEventsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView];
    [self showLoadingIndicator];
    self.noResultsFoundLabel.hidden = YES;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.shouldIncludeNumberedPrefixes = YES;
    }
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITCalendarEventCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITCalendarEventCell];
    self.tableView.scrollsToTop = YES;
}

- (void)showLoadingIndicator
{
    self.tableView.hidden = YES;
    self.activityIndicator.hidden = NO;
}

- (void)hideLoadingIndicator
{
    self.tableView.hidden = NO;
    self.activityIndicator.hidden = YES;
}

- (void)showNoResultsLabel
{
    self.tableView.hidden = YES;
    self.noResultsFoundLabel.hidden = NO;
}

#pragma mark - TableView Delegate/Datsource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.events.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITCalendarsEvent *event = self.events[indexPath.row];
    return [MITCalendarEventCell heightForEvent:event
                               withNumberPrefix:[self numberPrefixForIndexPath:indexPath]
                                 tableViewWidth:self.view.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITCalendarEventCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarEventCell forIndexPath:indexPath];
    
    MITCalendarsEvent *event = self.events[indexPath.row];
    NSString *numberPrefix = event.isHoliday ? nil : [self numberPrefixForIndexPath:indexPath];
    [cell setEvent:event withNumberPrefix:numberPrefix];
    if (self.shouldIndicateCellSelectedState) {
        [cell setBackgroundSelected:[indexPath isEqual:self.selectedIndexPath]];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.shouldIndicateCellSelectedState) {
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:self.selectedIndexPath];
        [(MITCalendarEventCell *)oldCell setBackgroundSelected:NO];
        self.selectedIndexPath = indexPath;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [(MITCalendarEventCell *)cell setBackgroundSelected:YES];
    }
    
    [self.delegate eventsTableView:self didSelectEvent:self.events[indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (NSString *)numberPrefixForIndexPath:(NSIndexPath *)indexPath {
    if (!self.shouldIncludeNumberedPrefixes) {
        return nil;
    }
    else {
        NSUInteger row = indexPath.row;
        
        __block int holidayEventsOffset = 0;
        if (self.indexesOfHolidayEvents.count > 0) {
            [self.indexesOfHolidayEvents enumerateObjectsUsingBlock:^(NSNumber *indexObject, NSUInteger idx, BOOL *stop) {
                NSUInteger indexValue = indexObject.unsignedIntegerValue;
                if (indexValue < row) {
                    holidayEventsOffset++;
                } else {
                    (*stop) = YES;
                }
            }];
        }
        
        int defaultOffset = row + 1; // Index 0 == number 1, etc.
        int actualOffset = defaultOffset - holidayEventsOffset;
        
        return [NSString stringWithFormat:@"%i", actualOffset];
    }
}

#pragma mark - Initial Selection

- (void)selectFirstRow
{
    if (self.shouldIndicateCellSelectedState) {
        if (self.events.count > 0) {
            NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            self.selectedIndexPath = firstIndexPath;
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:firstIndexPath];
            [(MITCalendarEventCell *)cell setBackgroundSelected:YES];
        }
    }
}

#pragma mark - Setters

- (void)setEvents:(NSArray *)events
{
    _events = events;
    
    self.indexesOfHolidayEvents = [NSMutableArray array];
    [events enumerateObjectsUsingBlock:^(MITCalendarsEvent *event, NSUInteger idx, BOOL *stop) {
        if (event.isHoliday) {
            [self.indexesOfHolidayEvents addObject:@(idx)];
        }
    }];
    
    [self.tableView reloadData];
    if (events) {
        [self hideLoadingIndicator];
        if (events.count == 0) {
            [self showNoResultsLabel];
        }
    }
    else {
        [self showLoadingIndicator];
    }
}

@end
