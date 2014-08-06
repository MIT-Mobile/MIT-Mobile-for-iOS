#import "MITEventSearchViewController.h"
#import "MITCalendarWebservices.h"
#import "MITCalendarManager.h"
#import "MITCalendarsEvent.h"
#import "MITCalendarEventCell.h"
#import "MITEventDetailViewController.h"
#import "MITCalendarEventDateGroupedDataSource.h"
#import "UIKit+MITAdditions.h"

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

static NSString *const kMITCalendarEventCellNibName = @"MITCalendarEventCell";

static NSString *const kMITCalendarFilterCellIdentifier = @"kMITCalendarFilterCellIdentifier";
static NSString *const kMITCalendarTypeAheadSuggestionCellIdentifier = @"kMITCalendarTypeAheadSuggestionCellIdentifier";
static NSString *const kMITCalendarEventCellIdentifier = @"kMITCalendarEventCellIdentifier";
static NSString *const kMITCalendarResultsCountCellIdentifier = @"kMITCalendarNoResultsCellIdentifier";
static NSString *const kMITCalendarContinueSearchingCellIdentifier = @"kMITCalendarContinueSearchingCellIdentifier";

static NSInteger const kMITCalendarEventSearchTypeAheadSectionFilters = 0;
static NSInteger const kMITCalendarEventSearchTypeAheadSectionSuggestions = 1;

@interface MITEventSearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *searchingSpinner;

@property (nonatomic) MITEventSearchViewControllerState state;
@property (nonatomic) MITEventSearchViewControllerResultsTimeframe resultsTimeframe;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewBottomLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *tableViewTopLayoutConstraint;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) MITCalendarEventDateGroupedDataSource *resultsDataSource;
@property (nonatomic, strong) NSArray *typeAheadArray;

// Currently only a single MITCalendarsCalendar object. When additional filters are specified, perhaps a filter object will be useful to create
@property (nonatomic, strong) NSArray *filtersArray;
@property (nonatomic, strong) MITCalendarsCalendar *currentCalendar;
@property (nonatomic, strong) UILabel *currentCalendarLabel;
@property (nonatomic, strong) UIView *currentCalendarLabelContainerView;

@property (weak, nonatomic) UIView *navBarSeparatorView;
@property (strong, nonatomic) UIView *repositionedNavBarSeparatorView;

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

- (id)initWithCategory:(MITCalendarsCalendar *)category
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.currentCalendar = category;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setupSearchBar];
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navBarSeparatorView.hidden = YES;
    [self registerForKeyboardNotifications];
    [self refreshTypeAheadSuggestionsForText:self.searchBar.text];
    [self.searchBar becomeFirstResponder];
    self.state = MITEventSearchViewControllerStateTypeAhead;
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navBarSeparatorView.hidden = NO;
    [self unregisterForKeyboardNotifications];
}

- (void)setupSearchBar
{
    self.searchBar = [[UISearchBar alloc] initWithFrame:self.navigationController.navigationBar.bounds];
    self.searchBar.showsCancelButton = YES;
    self.searchBar.delegate = self;
    [self.navigationController.navigationBar addSubview:self.searchBar];
}

- (void)setupTableView
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarFilterCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarTypeAheadSuggestionCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:kMITCalendarEventCellNibName bundle:nil] forCellReuseIdentifier:kMITCalendarEventCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarResultsCountCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarContinueSearchingCellIdentifier];
}

- (void)addExtendedNavBar
{
    if (!self.currentCalendar) {
        return;
    }
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    UIColor *navbarGrey = [UIColor colorWithRed:248.0/255.0 green:248.0/255.0 blue:248.0/255.0 alpha:1.0];
    
    self.currentCalendarLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, self.view.frame.size.width, 20)];
    self.currentCalendarLabel.text = [NSString stringWithFormat:@"In %@", self.currentCalendar.name];
    self.currentCalendarLabel.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.currentCalendarLabel.font = [UIFont systemFontOfSize:14];
    self.currentCalendarLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.currentCalendarLabel];
    
    self.currentCalendarLabelContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, navigationBar.frame.origin.y + navigationBar.frame.size.height, self.view.frame.size.width, 20)];
    self.currentCalendarLabelContainerView.backgroundColor = navbarGrey;
    [self.currentCalendarLabelContainerView addSubview:self.currentCalendarLabel];
    [self.view addSubview:self.currentCalendarLabelContainerView];
    
    self.tableViewTopLayoutConstraint.constant = 20;
    
    self.navBarSeparatorView = [self findHairlineImageViewUnder:navigationBar];
    self.navBarSeparatorView.hidden = YES;
    
    self.repositionedNavBarSeparatorView = [[UIImageView alloc] initWithFrame:self.navBarSeparatorView.frame];
    self.repositionedNavBarSeparatorView.backgroundColor = [UIColor colorWithRed:150.0/255.0 green:152.0/255.0 blue:156.0/255.0 alpha:1.0];
    CGRect repositionedFrame = self.repositionedNavBarSeparatorView.frame;
    repositionedFrame.origin.y = self.currentCalendarLabelContainerView.frame.size.height - self.repositionedNavBarSeparatorView.frame.size.height;
    self.repositionedNavBarSeparatorView.frame = repositionedFrame;
    self.repositionedNavBarSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.currentCalendarLabelContainerView addSubview:self.repositionedNavBarSeparatorView];
    
    navigationBar.opaque = YES;
    navigationBar.translucent = NO;
    [navigationBar setBarTintColor:navbarGrey];
}

- (void)removeExtendedNavBar
{
    [self.currentCalendarLabelContainerView removeFromSuperview];
    self.tableViewTopLayoutConstraint.constant = 0;
    self.navBarSeparatorView.hidden = NO;
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
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

// Only single calendar filters for now. This will need to change when more filters are added
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
    
    NSUInteger indexOfMatchingRecent = [mutableRecents indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSString *recent = obj;
        if ([[recent lowercaseString] isEqualToString:[recentSearch lowercaseString]]) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    
    if (indexOfMatchingRecent != NSNotFound) {
        [mutableRecents removeObjectAtIndex:indexOfMatchingRecent];
    }
    
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

#pragma mark - Searching

- (void)searchInNextMonth:(NSString *)searchText
{
    self.resultsTimeframe = MITEventSearchViewControllerResultsTimeframeOneMonth;
    [self showLoadingSpinner];
    
    [self saveRecentEventSearch:searchText];
    [self.searchBar resignFirstResponder];
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        [MITCalendarWebservices getEventsWithinOneMonthInCalendar:masterCalendar.eventsCalendar category:self.currentCalendar forQuery:searchText completion:^(NSArray *events, NSError *error) {
            self.state = MITEventSearchViewControllerStateResults;
            [self addExtendedNavBar];
            if (error) {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:nil];
            } else {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:events];
            }
            [self hideLoadingSpinner];
            [self.tableView reloadData];
        }];
    }];
}

- (void)searchInNextYear:(NSString *)searchText
{
    self.resultsTimeframe = MITEventSearchViewControllerResultsTimeframeOneYear;
    
    [[MITCalendarManager sharedManager] getCalendarsCompletion:^(MITMasterCalendar *masterCalendar, NSError *error) {
        [MITCalendarWebservices getEventsWithinOneYearInCalendar:masterCalendar.eventsCalendar category:self.currentCalendar forQuery:searchText completion:^(NSArray *events, NSError *error) {
            self.state = MITEventSearchViewControllerStateResults;
            if (error) {
                // Do nothing. The user already has results for the next month and so we will just keep displaying them and reload the "x results in next year" cell so it looks like 0 more results were found
            } else {
                self.resultsDataSource = [[MITCalendarEventDateGroupedDataSource alloc] initWithEvents:events];
            }
            [self.tableView reloadData];
        }];
    }];
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (self.state != MITEventSearchViewControllerStateTypeAhead) {
        self.state = MITEventSearchViewControllerStateTypeAhead;
        [self removeExtendedNavBar];
    }
    [self refreshTypeAheadSuggestionsForText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchInNextMonth:searchBar.text];
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
            if (indexPath.section == kMITCalendarEventSearchTypeAheadSectionSuggestions) {
                NSString *searchText = self.typeAheadArray[indexPath.row];
                self.searchBar.text = searchText;
                [self searchInNextMonth:searchText];
            }
            break;
        }
        case MITEventSearchViewControllerStateResults: {
            
            if ([self.resultsDataSource allSections].count > indexPath.section) {
//                MITEventDetailViewController *detailVC = [[MITEventDetailViewController alloc] initWithNibName:nil bundle:nil];
//                detailVC.event = [self.resultsDataSource eventForIndexPath:indexPath];
//                [self.navigationController pushViewController:detailVC animated:YES];
            } else {
                if (indexPath.row == 1) {
                    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    cell.accessoryView = spinner;
                    [spinner startAnimating];
                    [self searchInNextYear:self.searchBar.text];
                }
            }
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
            if ([self.resultsDataSource allSections].count > section) {
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
                }
            }
        }
        default: {
            return [UITableViewCell new];
        }
    }
}

@end
