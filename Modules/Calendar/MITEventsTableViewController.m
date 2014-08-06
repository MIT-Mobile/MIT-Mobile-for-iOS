#import "MITEventsTableViewController.h"
#import "MITCalendarEventCell.h"
#import "MITCalendarsEvent.h"

static NSString *const kMITCalendarEventCell = @"MITCalendarEventCell";

@interface MITEventsTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation MITEventsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableView];
    [self showLoadingIndicator];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:kMITCalendarEventCell bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMITCalendarEventCell];
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
    return [MITCalendarEventCell heightForEvent:event tableViewWidth:self.view.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITCalendarEventCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarEventCell forIndexPath:indexPath];
    
    [cell setEvent:self.events[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.delegate eventsTableView:self didSelectEvent:self.events[indexPath.row]];
}

#pragma mark - Setters

- (void)setEvents:(NSArray *)events
{
    _events = events;
    [self.tableView reloadData];
    if (events) {
        [self hideLoadingIndicator];
    }
    else {
        [self showLoadingIndicator];
    }
}

@end
