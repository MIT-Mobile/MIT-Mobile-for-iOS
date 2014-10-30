#import "MITEventSearchResultsViewController.h"
#import "MITCalendarEventDateGroupedDataSource.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarEventCell.h"
#import "MITEventsRecentSearches.h"
#import "MITCalendarManager.h"
#import "MITCalendarWebservices.h"
#import "UIKit+MITAdditions.h"

static NSString *const kMITCalendarEventCellNibName = @"MITCalendarEventCell";
static NSString *const kMITCalendarEventCellIdentifier = @"kMITCalendarEventCellIdentifier";
static NSString *const kMITCalendarResultsCountCellIdentifier = @"kMITCalendarNoResultsCellIdentifier";
static NSString *const kMITCalendarContinueSearchingCellIdentifier = @"kMITCalendarContinueSearchingCellIdentifier";

typedef NS_ENUM(NSInteger, MITEventSearchViewControllerResultsTimeframe) {
    MITEventSearchViewControllerResultsTimeframeOneMonth,
    MITEventSearchViewControllerResultsTimeframeOneYear
};

@interface MITEventSearchResultsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *searchingSpinner;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITCalendarEventDateGroupedDataSource *resultsDataSource;
@property (nonatomic) MITEventSearchViewControllerResultsTimeframe resultsTimeframe;
@property (nonatomic, strong) NSString *currentQuery;

@end

@implementation MITEventSearchResultsViewController

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
    // Do any additional setup after loading the view from its nib.
    
    [self setupTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTableView
{
    [self.tableView registerNib:[UINib nibWithNibName:kMITCalendarEventCellNibName bundle:nil] forCellReuseIdentifier:kMITCalendarEventCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarResultsCountCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarContinueSearchingCellIdentifier];
}

- (void)showLoadingSpinner
{
    self.tableView.hidden = YES;
    [self.searchingSpinner startAnimating];
}

- (void)hideLoadingSpinner
{
    self.tableView.hidden = NO;
    [self.searchingSpinner stopAnimating];
}

#pragma mark - Searching

- (void)beginSearch:(NSString *)searchString
{
    self.currentQuery = searchString;
    [self searchInNextMonth:searchString];
}

- (void)searchInNextMonth:(NSString *)searchText
{
    self.resultsTimeframe = MITEventSearchViewControllerResultsTimeframeOneMonth;
    [self showLoadingSpinner];
    
    [MITEventsRecentSearches saveRecentEventSearch:searchText];
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        [MITCalendarWebservices getEventsWithinOneMonthInCalendar:masterCalendar.eventsCalendar category:self.currentCalendar forQuery:searchText completion:^(NSArray *events, NSError *error) {
            if (error) {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:nil];
            } else {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:events];
            }
            [self hideLoadingSpinner];
            [self.tableView reloadData];
            if ([self.delegate respondsToSelector:@selector(eventSearchResultsViewController:didLoadResults:)]) {
                [self.delegate eventSearchResultsViewController:self didLoadResults:self.resultsDataSource.events];
            }
        }];
    }];
}

- (void)searchInNextYear:(NSString *)searchText
{
    self.resultsTimeframe = MITEventSearchViewControllerResultsTimeframeOneYear;
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        [MITCalendarWebservices getEventsWithinOneYearInCalendar:masterCalendar.eventsCalendar category:self.currentCalendar forQuery:searchText completion:^(NSArray *events, NSError *error) {
            if (error) {
                // Do nothing. The user already has results for the next month and so we will just keep displaying them and reload the "x results in next year" cell so it looks like 0 more results were found
            } else {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:events];
                if ([self.delegate respondsToSelector:@selector(eventSearchResultsViewController:didLoadResults:)]) {
                    [self.delegate eventSearchResultsViewController:self didLoadResults:self.resultsDataSource.events];
                }
            }
            [self.tableView reloadData];
        }];
    }];
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.resultsDataSource allSections].count > indexPath.section) {
        MITCalendarsEvent *event = [self.resultsDataSource eventForIndexPath:indexPath];
        return [MITCalendarEventCell heightForEvent:event withNumberPrefix:nil tableViewWidth:self.tableView.frame.size.width];
    } else {
        return 44;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.resultsDataSource allSections].count > indexPath.section) {
        if ([self.delegate respondsToSelector:@selector(eventSearchResultsViewController:didSelectEvent:)]) {
            [self.delegate eventSearchResultsViewController:self didSelectEvent:[self.resultsDataSource eventForIndexPath:indexPath]];
        }
    } else {
        if (indexPath.row == 1) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            cell.accessoryView = spinner;
            [spinner startAnimating];
            [self searchInNextYear:self.currentQuery];
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self.resultsDataSource allSections].count > section) {
        return [self.resultsDataSource headerForSection:section];
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.resultsDataSource allSections].count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.resultsDataSource allSections].count > section) {
        return [self.resultsDataSource eventsInSection:section].count;
    } else {
        switch (self.resultsTimeframe) {
            case MITEventSearchViewControllerResultsTimeframeOneMonth: {
                return 2;
            }
            case MITEventSearchViewControllerResultsTimeframeOneYear: {
                return 1;
            }
            default: {
                return 0;
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.resultsDataSource allSections].count > indexPath.section) {
        MITCalendarEventCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarEventCellIdentifier forIndexPath:indexPath];
        MITCalendarsEvent *event = [self.resultsDataSource eventForIndexPath:indexPath];
        [cell setEvent:event withNumberPrefix:nil];
        return cell;
    } else {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarResultsCountCellIdentifier];
            NSInteger numberOfResults = [self.resultsDataSource events].count;
            
            NSString *timeFrameString = @"";
            if (self.resultsTimeframe == MITEventSearchViewControllerResultsTimeframeOneMonth) {
                timeFrameString = @"month";
            } else if (self.resultsTimeframe == MITEventSearchViewControllerResultsTimeframeOneYear) {
                timeFrameString = @"year";
            }
            
            cell.textLabel.text = [NSString stringWithFormat:@"%i results in the next %@", numberOfResults, timeFrameString];
            cell.textLabel.textColor = [UIColor darkGrayColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else if (indexPath.row == 1) {
            UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarContinueSearchingCellIdentifier];
            cell.textLabel.text = @"Continue Searching...";
            cell.textLabel.textColor = [UIColor mit_tintColor];
            cell.accessoryView = nil;
            return cell;
        } else {
            return [UITableViewCell new];
        }
    }
}

@end
