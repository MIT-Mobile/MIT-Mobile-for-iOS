#import "FacilitiesRoomViewController.h"

#import "FacilitiesCategory.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesTypeViewController.h"
#import "HighlightTableViewCell.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"

@implementation FacilitiesRoomViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;

@synthesize locationData = _locationData;
@synthesize filteredData = _filteredData;
@synthesize searchString = _searchString;
@synthesize trimmedString = _trimmedString;

@synthesize location = _location;

@dynamic cachedData;
@dynamic filterPredicate;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
        self.locationData = [FacilitiesLocationData sharedData];
    }
    return self;
}

- (void)dealloc
{
	self.location = nil;
    self.tableView = nil;
    self.loadingView = nil;
    self.locationData = nil;
    self.searchString = nil;

    self.filterPredicate = nil;
    self.filteredData = nil;
    self.cachedData = nil;
    [super dealloc];
}


#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
    UIView *mainView = [[[UIView alloc] initWithFrame:screenFrame] autorelease];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor clearColor];
    
    
    CGRect searchBarFrame = CGRectZero;
    
    {
        UISearchBar *searchBar = [[[UISearchBar alloc] init] autorelease];
        searchBar.delegate = self;
        searchBar.barStyle = UIBarStyleBlackOpaque;
        
        UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar
                                                                                         contentsController:self];
        searchController.delegate = self;
        searchController.searchResultsDataSource = self;
        searchController.searchResultsDelegate = self;
        
        [searchBar sizeToFit];
        searchBarFrame = searchBar.frame;
        [mainView addSubview:searchBar];
    }
    
    {
        CGRect tableRect = screenFrame;
        tableRect.origin = CGPointMake(0, searchBarFrame.size.height);
        tableRect.size.height -= searchBarFrame.size.height;
        
        UITableView *tableView = [[[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped] autorelease];
        [tableView applyStandardColors];
        
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;
        
        self.tableView = tableView;
        [mainView addSubview:tableView];
    }
    
    
    {
        CGRect loadingFrame = screenFrame;
        loadingFrame.origin = CGPointMake(0, searchBarFrame.size.height);
        loadingFrame.size.height -= searchBarFrame.size.height;
        
        MITLoadingActivityView *loadingView = [[[MITLoadingActivityView alloc] initWithFrame:loadingFrame] autorelease];
        loadingView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                             UIViewAutoresizingFlexibleWidth);
        loadingView.backgroundColor = [UIColor clearColor];
        
        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.cachedData = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.locationData addObserver:self
                         withBlock:^(NSString *notification, BOOL updated, id userData) {
                             if ((notification == nil) || [userData isEqualToString:FacilitiesRoomsKey]) {
                                 [self.loadingView removeFromSuperview];
                                 self.loadingView = nil;
                                 self.tableView.hidden = NO;
                                 
                                 if ((self.cachedData == nil) || updated) {
                                     self.cachedData = nil;
                                     [self.tableView reloadData];
                                 }
                                 
                                 if ([self.searchDisplayController isActive] && ((self.filteredData == nil) || updated)) {
                                     self.filteredData = nil;
                                     [self.searchDisplayController.searchResultsTableView reloadData];
                                 }
                             }
                         }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationData removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Public Methods
- (NSArray*)dataForMainTableView {
    NSArray *data = [self.locationData roomsForBuilding:self.location.number];
    data = [data sortedArrayUsingComparator: ^(id obj1, id obj2) {
        FacilitiesRoom *r1 = (FacilitiesRoom*)obj1;
        FacilitiesRoom *r2 = (FacilitiesRoom*)obj2;
        NSString *s1 = [r1 displayString];
        NSString *s2 = [r2 displayString];
        
        return [s1 caseInsensitiveCompare:s2];
    }];
    
    return data;
}

- (NSArray*)resultsForSearchString:(NSString *)searchText {
    NSArray *results = [self.cachedData filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSRange range = [[evaluatedObject description] rangeOfString:searchText
                                                             options:NSCaseInsensitiveSearch];
        return (range.location != NSNotFound);
    }]];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b[\\S]*%@[\\S]*\\b",searchText]
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:NULL];
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [(FacilitiesRoom*)obj1 displayString];
        NSString *key2 = [(FacilitiesRoom*)obj2 displayString];
        
        NSRange matchRange1 = [regex rangeOfFirstMatchInString:key1
                                                       options:0
                                                         range:NSMakeRange(0, [key1 length])];
        NSRange matchRange2 = [regex rangeOfFirstMatchInString:key2
                                                       options:0
                                                         range:NSMakeRange(0, [key2 length])];
        
        if (matchRange1.location > matchRange2.location) {
            return NSOrderedDescending;
        } else if (matchRange1.location < matchRange2.location) {
            return NSOrderedAscending;
        } else {
            return [key1 caseInsensitiveCompare:key2];
        }
    }];
    
    return results;
}

- (void)configureMainTableCell:(UITableViewCell *)cell
                  forIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        cell.textLabel.text = @"Outside";
    } else {
        if ([self.cachedData count] == 0) {
            cell.textLabel.text = @"Inside";
        } else {
            FacilitiesRoom *room = [self.cachedData objectAtIndex:indexPath.row];
            cell.textLabel.text = [room displayString];
        }
    }
}

- (void)configureSearchCell:(HighlightTableViewCell *)cell
               forIndexPath:(NSIndexPath *)indexPath
{
    FacilitiesRoom *room = [self.filteredData objectAtIndex:indexPath.row];
    if (room) {
        cell.highlightLabel.text = [room displayString];
        cell.highlightLabel.searchString = self.searchString;
    }
}


#pragma mark - Dynamic Setters/Getters
- (void)setFilterPredicate:(NSPredicate *)filterPredicate {
    self.cachedData = nil;
    [_filterPredicate release];
    _filterPredicate = [filterPredicate retain];
}

- (NSPredicate*)filterPredicate {
    return _filterPredicate;
}

- (void)setCachedData:(NSArray *)cachedData {
    if (_cachedData != nil) {
        [_cachedData release];
    }
    
    _cachedData = [cachedData retain];
}

- (NSArray*)cachedData {
    if (_cachedData == nil) {
        [self setCachedData:[self dataForMainTableView]];
    }
    
    return _cachedData;
}

- (void)setFilteredData:(NSArray *)filteredData {
    [_filteredData release];
    _filteredData = [filteredData retain];
}

- (NSArray*)filteredData {
    if (_filteredData == nil && [self.searchString length] > 0) {
        [self setFilteredData:[self resultsForSearchString:self.searchString]];
    }
    
    return _filteredData;
}


#pragma mark - UITableViewDelegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    FacilitiesRoom *room = nil;
    NSString *altName = nil;
    
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            altName = @"Outside";
        } else if ([self.cachedData count] == 0) {
            altName = @"Inside";
        } else {
            room = [self.cachedData objectAtIndex:indexPath.row];
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (indexPath.row == 0) {
            altName = self.searchString;
        } else {
            room = [self.filteredData objectAtIndex:(indexPath.row-1)];
        }
    }
    
    FacilitiesTypeViewController *vc = [[[FacilitiesTypeViewController alloc] init] autorelease];
    
    if (room) {
        [dict setObject: room
                 forKey: FacilitiesRequestLocationRoomKey];
    } else {
        [dict setObject: altName
                 forKey: FacilitiesRequestLocationUserRoomKey];
    }
    
    [dict setObject: self.location
             forKey: FacilitiesRequestLocationBuildingKey];
    
    vc.userData = dict;
    
    [self.navigationController pushViewController:vc
                                         animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath
                             animated:YES];
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if ((self.cachedData == nil) || ([self.cachedData count] == 0)) {
            return 1;
        } else {
            return (section == 0) ? 1 : [self.cachedData count];
        } 
    } else {
        return ([self.trimmedString length] > 0) ? [self.filteredData count] + 1 : 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    static NSString *searchIdentifier = @"searchCell";
    
    if (tableView == self.tableView) {
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:facilitiesIdentifier];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:facilitiesIdentifier] autorelease];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        [self configureMainTableCell:cell 
                        forIndexPath:indexPath];
        return cell;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        HighlightTableViewCell *hlCell = nil;
        hlCell = (HighlightTableViewCell*)[tableView dequeueReusableCellWithIdentifier:searchIdentifier];
        
        if (hlCell == nil) {
            hlCell = [[[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:searchIdentifier] autorelease];
            
            hlCell.autoresizesSubviews = YES;
            hlCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (indexPath.row == 0) {
            hlCell.highlightLabel.searchString = nil;
            hlCell.highlightLabel.text = [NSString stringWithFormat:@"Use \"%@\"",self.searchString];
        } else {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(indexPath.row-1)
                                                   inSection:indexPath.section];
            [self configureSearchCell:hlCell
                         forIndexPath:path];
        }
        
        
        return hlCell;
    } else {
        return nil;
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.searchString isEqualToString:self.trimmedString]) {
        self.searchString = ([self.trimmedString length] > 0) ? self.trimmedString : nil;
        self.filteredData = nil;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO
                                   animated:YES];
}

// Make sure tapping the status bar always scrolls to the top of the active table
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    self.tableView.scrollsToTop = NO;
    tableView.scrollsToTop = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView {
    // using willUnload because willHide strangely doesn't get called when the "Cancel" button is clicked
    tableView.scrollsToTop = NO;
    self.tableView.scrollsToTop = YES;
}

@end
