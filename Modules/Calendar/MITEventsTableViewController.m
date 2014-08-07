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
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.shouldIncludeNumberedPrefixes = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self setupTableViewInsetsForIPad];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupTableViewInsetsForIPad
{
    CGFloat statusBarWidth = CGRectGetWidth([UIApplication sharedApplication].statusBarFrame);
    CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    CGFloat statusBarOffset = statusBarWidth < statusBarHeight ? statusBarWidth : statusBarHeight;
    CGFloat navBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat toolbarHeight = CGRectGetHeight(self.navigationController.toolbar.bounds);
    self.tableView.contentInset = UIEdgeInsetsMake(statusBarOffset + navBarHeight, 0, toolbarHeight, 0);
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
    return [MITCalendarEventCell heightForEvent:event
                               withNumberPrefix:[self numberPrefixForIndexPath:indexPath]
                                 tableViewWidth:self.view.frame.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITCalendarEventCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarEventCell forIndexPath:indexPath];
    
    [cell setEvent:self.events[indexPath.row] withNumberPrefix:[self numberPrefixForIndexPath:indexPath]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.delegate eventsTableView:self didSelectEvent:self.events[indexPath.row]];
}

- (NSString *)numberPrefixForIndexPath:(NSIndexPath *)indexPath {
    if (!self.shouldIncludeNumberedPrefixes) {
        return nil;
    }
    else {
        return [NSString stringWithFormat:@"%i", indexPath.row + 1];
    }
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
