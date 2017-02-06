#import "MITEventSearchTypeAheadViewController.h"
#import "MITCalendarsCalendar.h"
#import "MITEventsRecentSearches.h"

static NSInteger const kMITCalendarEventSearchTypeAheadSectionFilters = 0;
static NSInteger const kMITCalendarEventSearchTypeAheadSectionSuggestions = 1;

static NSString *const kMITCalendarFilterCellIdentifier = @"kMITCalendarFilterCellIdentifier";
static NSString *const kMITCalendarTypeAheadSuggestionCellIdentifier = @"kMITCalendarTypeAheadSuggestionCellIdentifier";

@interface MITEventSearchTypeAheadViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSString *currentQuery;
@property (nonatomic, strong) NSArray *typeAheadArray;

// Currently only a single MITCalendarsCalendar object. When additional filters are specified, perhaps a filter object will be useful to create
@property (nonatomic, strong) NSArray *filtersArray;

@end

@implementation MITEventSearchTypeAheadViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateWithTypeAheadText:self.currentQuery];
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

- (void)setupTableView
{
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarFilterCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMITCalendarTypeAheadSuggestionCellIdentifier];
}

- (NSArray *)recentSuggestionsForTypeAheadText:(NSString *)typeAheadText
{
    if (typeAheadText == nil || [typeAheadText isEqualToString:@""]) {
        return [[MITEventsRecentSearches recentSearches] array];
    }
    
    NSMutableArray *filteredRecents = [NSMutableArray array];
    NSString *lowercaseTypeAheadText = [typeAheadText lowercaseString];
    for (NSString *recent in [MITEventsRecentSearches recentSearches]) {
        NSString *lowercaseRecent = [recent lowercaseString];
        if ([lowercaseRecent hasPrefix:lowercaseTypeAheadText]) {
            [filteredRecents addObject:recent];
        }
    }
    return filteredRecents;
}

- (void)clearFilters
{
    self.currentCalendar = nil;
    if ([self.delegate respondsToSelector:@selector(eventSearchTypeAheadControllerDidClearFilters:)]) {
        [self.delegate eventSearchTypeAheadControllerDidClearFilters:self];
    }
    [self.tableView reloadData];
}

#pragma mark - Public Methods

- (void)updateWithTypeAheadText:(NSString *)typeAheadText
{
    self.currentQuery = typeAheadText;
    self.typeAheadArray = [self recentSuggestionsForTypeAheadText:typeAheadText];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == kMITCalendarEventSearchTypeAheadSectionSuggestions) {
        NSString *searchText = self.typeAheadArray[indexPath.row];
        if ([self.delegate respondsToSelector:@selector(eventSearchTypeAheadController:didSelectSuggestion:)]) {
            [self.delegate eventSearchTypeAheadController:self didSelectSuggestion:searchText];
        }
    }
}

#pragma mark - UITableViewDataSource Methods

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    [[(UITableViewHeaderFooterView *)view textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case kMITCalendarEventSearchTypeAheadSectionFilters: {
            if (self.filtersArray.count > 0) {
                return 26.0;
            } else {
                return 0;
            }
            break;
        }
        case kMITCalendarEventSearchTypeAheadSectionSuggestions: {
            return 26.0;
            break;
        }
        default: {
            return 0;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
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
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}

#pragma mark - Rotation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end
