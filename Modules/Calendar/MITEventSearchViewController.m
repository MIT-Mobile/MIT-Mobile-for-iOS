#import "MITEventSearchViewController.h"
#import "MITCalendarWebservices.h"
#import "MITCalendarManager.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarEventCell.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarEventDateGroupedDataSource.h"

typedef NS_ENUM(NSInteger, MITEventSearchViewControllerState) {
    MITEventSearchViewControllerStateTypeAhead,
    MITEventSearchViewControllerStateResults
};

typedef NS_ENUM(NSInteger, MITEventSearchViewControllerResultsTimeframe) {
    MITEventSearchViewControllerResultsTimeframeOneMonth,
    MITEventSearchViewControllerResultsTimeframeOneYear
};

static NSString *const kMITCalendarEventRecentSearchesDefaultsKey = @"kMITCalendarEventRecentSearchesDefaultsKey";
static NSInteger const kMITCalendarEventRecentSearchesLimit = 50;

static NSString *const kMITCalendarFilterCellIdentifier = @"kMITCalendarFilterCellIdentifier";
static NSString *const kMITCalendarTypeAheadSuggestionCellIdentifier = @"kMITCalendarTypeAheadSuggestionCellIdentifier";
static NSString *const kMITCalendarEventCellIdentifier = @"kMITCalendarEventCellIdentifier";
static NSString *const kMITCalendarResultsCountCellIdentifier = @"kMITCalendarNoResultsCellIdentifier";
static NSString *const kMITCalendarContinueSearchingCellIdentifier = @"kMITCalendarContinueSearchingCellIdentifier";

static NSInteger const kMITCalendarEventSearchTypeAheadSectionFilters = 0;
static NSInteger const kMITCalendarEventSearchTypeAheadSectionSuggestions = 1;

@interface MITEventSearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic) MITEventSearchViewControllerState state;
@property (nonatomic) MITEventSearchViewControllerResultsTimeframe resultsTimeframe;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewBottomLayoutConstraint;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) MITCalendarEventDateGroupedDataSource *resultsDataSource;
@property (nonatomic, strong) NSArray *typeAheadArray;

// Currently only a single MITCalendarsCalendar object. When additional filters are specified, perhaps a filter object will be useful to create
@property (nonatomic, strong) NSArray *filtersArray;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;

@end

@implementation MITEventSearchViewController

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
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.bounds];
    self.searchBar.showsCancelButton = YES;
    self.searchBar.delegate = self;
    [self.navigationController.navigationBar addSubview:self.searchBar];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarFilterCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarTypeAheadSuggestionCellIdentifier];
    [self.tableView registerClass:[MITCalendarEventCell class] forCellReuseIdentifier:kMITCalendarEventCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarResultsCountCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarContinueSearchingCellIdentifier];
    
    self.currentCalendar = [[MITCalendarManager sharedManager] masterCalendar].eventsCalendar;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self registerForKeyboardNotifications];
    [self refreshTypeAheadSuggestionsForText:self.searchBar.text];
    [self.searchBar becomeFirstResponder];
    self.state = MITEventSearchViewControllerStateTypeAhead;
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self unregisterForKeyboardNotifications];
}

#pragma mark - Keyboard Height Actions

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        CGRect endFrame = [[notification.userInfo valueForKeyPath:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        // Apple doesn't give the keyboard frame in the current view's coordinate system, it gives it in the window one, so width/height can be reversed when in landscape mode.
        endFrame = [self.view convertRect:endFrame fromView:nil];
        
        self.tableViewBottomLayoutConstraint.constant = endFrame.size.height;
        [self.view setNeedsLayout];
        [self.view updateConstraintsIfNeeded];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.tableViewBottomLayoutConstraint.constant = 0;
        [self.view setNeedsLayout];
        [self.view updateConstraintsIfNeeded];
    }
}

#pragma mark - Filters

- (void)clearFilters
{
    self.currentCalendar = nil;
}

- (void)setCurrentCalendar:(MITCalendarsCalendar *)currentCalendar
{
    if (![_currentCalendar isEqual:currentCalendar]) {
        _currentCalendar = currentCalendar;
        if (_currentCalendar) {
            self.filtersArray = [NSArray arrayWithObject:_currentCalendar];
        } else {
            self.filtersArray = [NSArray array];
        }
        
        [self.tableView reloadData];
    }
}

#pragma mark - Recent Event Searches

- (void)saveRecentEventSearch:(NSString *)recentSearch
{
    NSMutableOrderedSet *mutableRecents = [[self recentSearches] mutableCopy];
    [mutableRecents insertObject:recentSearch atIndex:0];
    if (mutableRecents.count > kMITCalendarEventRecentSearchesLimit) {
        [mutableRecents removeObjectAtIndex:kMITCalendarEventRecentSearchesLimit];
    }
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSOrderedSet orderedSetWithOrderedSet:mutableRecents]] forKey:kMITCalendarEventRecentSearchesDefaultsKey];
}

- (NSOrderedSet *)recentSearches
{
    NSOrderedSet *recents = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:kMITCalendarEventRecentSearchesDefaultsKey]];
    if (!recents) {
        recents = [NSOrderedSet orderedSet];
    }
    return recents;
}

- (NSArray *)recentSuggestionsForTypeAheadText:(NSString *)typeAheadText
{
    if (typeAheadText == nil || [typeAheadText isEqualToString:@""]) {
        return [[self recentSearches] array];
    }
    
    NSMutableArray *filteredRecents = [NSMutableArray array];
    for (NSString *recent in [self recentSearches]) {
        if ([recent hasPrefix:typeAheadText]) {
            [filteredRecents addObject:recent];
        }
    }
    return filteredRecents;
}

- (void)refreshTypeAheadSuggestionsForText:(NSString *)typeAheadText
{
    self.typeAheadArray = [self recentSuggestionsForTypeAheadText:typeAheadText];
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self refreshTypeAheadSuggestionsForText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self saveRecentEventSearch:searchBar.text];
    [self.searchBar resignFirstResponder];
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        [MITCalendarWebservices getEventsWithinOneMonthInCalendar:masterCalendar.eventsCalendar forQuery:self.searchBar.text completion:^(NSArray *events, NSError *error) {
            self.state = MITEventSearchViewControllerStateResults;
            if (error) {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:nil];
            } else {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:events];
            }
            [self.tableView reloadData];
        }];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            return 44;
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            if ([self.resultsDataSource allSections].count > indexPath.section) {
                MITCalendarsEvent *event = [self.resultsDataSource eventForIndexPath:indexPath];
                return [MITCalendarEventCell heightForEvent:event tableViewWidth:self.tableView.frame.size.width];
            } else {
                return 44;
            }
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            break;
        }
        case MITEventSearchViewControllerStateResults: {
//            MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
//            detailVC.event = [self.resultsDataSource eventForIndexPath:indexPath];
//            [self.navigationController pushViewController:detailVC animated:YES];
            break;
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            switch (section) {
                case kMITCalendarEventSearchTypeAheadSectionFilters: {
                    if (self.filtersArray.count > 0) {
                        return @"FILTERS";
                    } else {
                        return nil;
                    }
                    break;
                }
                case kMITCalendarEventSearchTypeAheadSectionSuggestions: {
                    return @"RECENTS";
                    break;
                }
                default: {
                    return nil;
                }
            }
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            if ([self.resultsDataSource allSections].count < section) {
                return [self.resultsDataSource headerForSection:section];
            } else {
                return nil;
            }
        }
        default: {
            return nil;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            return 2;
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            return [self.resultsDataSource allSections].count + 1;
            break;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            switch (section) {
                case kMITCalendarEventSearchTypeAheadSectionFilters: {
                    return self.filtersArray.count;
                }
                case kMITCalendarEventSearchTypeAheadSectionSuggestions: {
                    return self.typeAheadArray.count;
                }
                default: {
                    return 0;
                }
            }
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            if ([self.resultsDataSource allSections].count < section) {
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
            break;
        }
        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.state) {
        case MITEventSearchViewControllerStateTypeAhead: {
            switch (indexPath.section) {
                case kMITCalendarEventSearchTypeAheadSectionFilters: {
                    UITableViewCell *filterCell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarFilterCellIdentifier forIndexPath:indexPath];
                    if (self.filtersArray.count > indexPath.row) {
                        MITCalendarsCalendar *filterCalendar = self.filtersArray[indexPath.row];
                        filterCell.textLabel.text = filterCalendar.name;
                        if (!filterCell.accessoryView) {
                            UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
                            [clearButton setFrame:CGRectMake(filterCell.bounds.size.width - 40, 0, 40, filterCell.bounds.size.height)];
                            [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
                            [clearButton addTarget:self action:@selector(clearFilters) forControlEvents:UIControlEventTouchUpInside];
                            filterCell.accessoryView = clearButton;
                        }
                    }
                    return filterCell;
                }
                case kMITCalendarEventSearchTypeAheadSectionSuggestions: {
                    UITableViewCell *suggestionCell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarTypeAheadSuggestionCellIdentifier forIndexPath:indexPath];
                    if (self.typeAheadArray.count > indexPath.row) {
                        suggestionCell.textLabel.text = self.typeAheadArray[indexPath.row];
                    }
                    return suggestionCell;
                }
                default: {
                    return [UITableViewCell new];
                }
            }
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            if ([self.resultsDataSource allSections].count > indexPath.section) {
                MITCalendarEventCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarEventCellIdentifier forIndexPath:indexPath];
                MITCalendarsEvent *event = [self.resultsDataSource eventForIndexPath:indexPath];
                [cell setEvent:event];
                return cell;
            } else {
                if (indexPath.row == 0) {
                    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarResultsCountCellIdentifier];
                    // return "x results in next month" cell
                    return cell;
                } else if (indexPath.row == 1) {
                    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kMITCalendarContinueSearchingCellIdentifier];
                    // return "continue searching" cell
                    return cell;
                }
            }
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

@end
