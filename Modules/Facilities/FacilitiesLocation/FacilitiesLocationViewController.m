#import "FacilitiesLocationViewController.h"

#import "MITBuildingServicesReportForm.h"
#import "FacilitiesCategory.h"
#import "FacilitiesConstants.h"
#import "FacilitiesLocation.h"
#import "FacilitiesLeasedViewController.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesLocationSearch.h"
#import "FacilitiesRoomViewController.h"
#import "FacilitiesTypeViewController.h"
#import "HighlightTableViewCell.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"

@interface FacilitiesLocationViewController ()
@property (nonatomic,strong) UISearchDisplayController *strongSearchDisplayController;
@property (nonatomic,strong) FacilitiesLocationSearch *searchHelper;
@property (nonatomic,strong) MITLoadingActivityView* loadingView;
@property (nonatomic,strong) FacilitiesLocationData* locationData;
@property (nonatomic,strong) NSPredicate* filterPredicate;

@property (nonatomic,strong) NSArray* cachedData;
@property (nonatomic,strong) NSArray* filteredData;
@property (nonatomic,strong) NSString* searchString;
@property (nonatomic,strong) NSString* trimmedString;
@property (nonatomic,strong) id observerToken;

- (NSArray*)dataForMainTableView;
- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
- (void)configureSearchCell:(HighlightTableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
@end

@implementation FacilitiesLocationViewController
- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
        self.locationData = [FacilitiesLocationData sharedData];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    self.searchHelper = nil;
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] bounds];
    
    UIView *mainView = [[UIView alloc] initWithFrame:screenFrame];
    mainView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                 UIViewAutoresizingFlexibleWidth);
    mainView.autoresizesSubviews = YES;
    mainView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        mainView.backgroundColor = [UIColor mit_backgroundColor];
    }
    
    
    CGRect searchBarFrame = CGRectZero;
    
    {
        CGRect tableRect = screenFrame;
        tableRect.origin = CGPointMake(0, searchBarFrame.size.height);
        tableRect.size.height -= searchBarFrame.size.height;
        
        UITableView *tableView = [[UITableView alloc] initWithFrame: tableRect
                                                               style: UITableViewStyleGrouped];
        
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
        
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight |
                                           UIViewAutoresizingFlexibleWidth);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.hidden = YES;
        tableView.scrollEnabled = YES;
        tableView.autoresizesSubviews = YES;
        [tableView setBackgroundColor:[UIColor whiteColor]];
        
        self.tableView = tableView;
        [mainView addSubview:tableView];
    }
    
    {
        UISearchBar *searchBar = [[UISearchBar alloc] init];
        searchBar.delegate = self;
        
        UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar
                                                                                        contentsController:self];
        searchController.delegate = self;
        searchController.searchResultsDataSource = self;
        searchController.searchResultsDelegate = self;
        self.strongSearchDisplayController = searchController;
        
        // while we still need to initialize searchController for both iPhone and iPad,
        // we only need add search bar to the view for the iPhone case
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
        {
            [searchBar sizeToFit];
            searchBarFrame = searchBar.frame;
            self.tableView.tableHeaderView = searchBar;
        }
    }
    
    {
        CGRect loadingFrame = screenFrame;
        loadingFrame.origin = CGPointMake(0, searchBarFrame.size.height);
        loadingFrame.size.height -= searchBarFrame.size.height;
        
        MITLoadingActivityView *loadingView = [[MITLoadingActivityView alloc] initWithFrame:loadingFrame];
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
    
    if( self.category.name )
    {
        self.title = self.category.name;
    }
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:nil
                                                                  action:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.cachedData = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(customLocationTextDidChange:)
                                                 name:MITBuildingServicesLocationCustomTextNotification
                                               object:nil];
    
    if (self.observerToken == nil)
    {
        FacilitiesLocationViewController *weakSelf = self;
        self.observerToken = [self.locationData addUpdateObserver:^(NSString *notification, BOOL updated, id userData) {
            FacilitiesLocationViewController *blockSelf = weakSelf;
            BOOL commandMatch = ([userData isEqualToString:FacilitiesLocationsKey]);
            if (blockSelf && commandMatch) {
                [blockSelf.loadingView removeFromSuperview];
                blockSelf.loadingView = nil;
                blockSelf.tableView.hidden = NO;
                
                if ((blockSelf.cachedData == nil) || updated) {
                    blockSelf.cachedData = nil;
                    [blockSelf.tableView reloadData];
                }
                
                if ([blockSelf.searchDisplayController isActive] && ((weakSelf.filteredData == nil) || updated)) {
                    blockSelf.filteredData = nil;
                    [blockSelf.searchDisplayController.searchResultsTableView reloadData];
                }
            }
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.observerToken) {
        [[FacilitiesLocationData sharedData] removeUpdateObserver:self.observerToken];
        self.observerToken = nil;
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Public Methods
- (NSArray*)dataForMainTableView {
    NSMutableArray *data = nil;
    data = [NSMutableArray arrayWithArray:[self.locationData locationsInCategory:self.category.uid]];
    [data removeObjectsInArray:[self.locationData hiddenBuildings]];
    [data sortUsingComparator: ^(id obj1, id obj2) {
        FacilitiesLocation *l1 = (FacilitiesLocation*)obj1;
        FacilitiesLocation *l2 = (FacilitiesLocation*)obj2;
        NSString *k1 = nil;
        NSString *k2 = nil;

        if ([l1.number length] == 0) {
            k1 = l1.name;
        } else {
            k1 = l1.number;
        }

        if ([l2.number length] == 0) {
            k2 = l2.name;
        } else {
            k2 = l2.number;
        }

        return [k1 compare:k2
                   options:(NSCaseInsensitiveSearch | NSNumericSearch)];
    }];
    
    return [NSArray arrayWithArray:data];
}

- (NSArray*)resultsForSearchString:(NSString *)searchText {
    if (self.searchHelper == nil) {
        self.searchHelper = [[FacilitiesLocationSearch alloc] init];
    }
    
    self.searchHelper.category = self.category;
    self.searchHelper.searchString = searchText;
    NSArray *results = [self.searchHelper searchResults];
    
    results = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *key1 = [obj1 valueForKey:FacilitiesSearchResultDisplayStringKey];
        NSString *key2 = [obj2 valueForKey:FacilitiesSearchResultDisplayStringKey];
        
        return [key1 compare:key2
                     options:(NSCaseInsensitiveSearch |
                              NSNumericSearch |
                              NSForcedOrderingSearch)];
    }];
    
    return results;
}

- (void)configureMainTableCell:(UITableViewCell*)cell
                  forIndexPath:(NSIndexPath*)indexPath {
    if ([self.cachedData count] >= indexPath.row) {
        FacilitiesLocation *location = [self.cachedData objectAtIndex:indexPath.row];
        cell.textLabel.text = [location displayString];
    }
}

- (void)configureSearchCell:(HighlightTableViewCell *)cell
               forIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *loc = [self.filteredData objectAtIndex:indexPath.row];
    
    cell.highlightLabel.searchString = self.searchString;
    cell.highlightLabel.text = [loc objectForKey:FacilitiesSearchResultDisplayStringKey];
}


#pragma mark - Dynamic Setters/Getters
- (void)setFilterPredicate:(NSPredicate *)filterPredicate {
    self.cachedData = nil;
    _filterPredicate = filterPredicate;
}

- (NSArray*)cachedData {
    if (_cachedData == nil) {
        self.cachedData = [self dataForMainTableView];
    }
    
    return _cachedData;
}

- (NSArray*)filteredData {
    if (_filteredData == nil && [self.searchString length] > 0) {
        self.filteredData = [self resultsForSearchString:self.searchString];
    }
    
    return _filteredData;
}

#pragma mark - notifications

// on iPad manually set searchText and add searchResultsTableView to the view hierarchy
// in order to show the filtered list.
- (void)customLocationTextDidChange:(NSNotification *)senderNotification
{
    // make sure this logic only occurs for the iPad.
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        return;
    }
    
    NSDictionary *userInfo = senderNotification.userInfo;
    
    if( userInfo == nil || userInfo[@"customText"] == nil )
    {
        return;
    }
    
    NSString *customLocationText = userInfo[@"customText"];
        
    [self handleUpdatedSearchText:customLocationText];
    
    [[MITBuildingServicesReportForm sharedServiceReport] setCustomLocation:self.searchString];
        
    if( customLocationText.length == 0 )
    {
        [self.strongSearchDisplayController.searchResultsTableView reloadData];
        [self.strongSearchDisplayController.searchResultsTableView removeFromSuperview];
    }
    else
    {
        if( [self.strongSearchDisplayController.searchResultsTableView superview] == nil )
        {
            [self.view addSubview:self.strongSearchDisplayController.searchResultsTableView];
            [self.strongSearchDisplayController.searchResultsTableView setFrame:self.tableView.frame];
            [self.strongSearchDisplayController.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
        }

        [self.strongSearchDisplayController.searchResultsTableView reloadData];
    }
}

#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.1f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FacilitiesLocation *location = nil;
    
    if (tableView == self.tableView) {
        location = (FacilitiesLocation*)[self.cachedData objectAtIndex:indexPath.row];
    }
    else
    {
        if (indexPath.row == 0)
        {
            [[MITBuildingServicesReportForm sharedServiceReport] setCustomLocation:self.searchString];
        }
        else
        {
            NSDictionary *dict = [self.filteredData objectAtIndex:(indexPath.row-1)];
            location = (FacilitiesLocation*)[dict objectForKey:FacilitiesSearchResultLocationKey];
        }
    }
    
    [[MITBuildingServicesReportForm sharedServiceReport] setLocation:location shouldSetRoom:![location.isLeased boolValue]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:MITBuildingServicesLocationChosenNoticiation object:nil];
    }
}


#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self.cachedData count];
    } else {
        return ([self.trimmedString length] > 0) ? [self.filteredData count] + 1 : 0;    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    static NSString *searchIdentifier = @"searchCell";
    
    if (tableView == self.tableView) {
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:facilitiesIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:facilitiesIdentifier];
        }
        
        [self configureMainTableCell:cell 
                        forIndexPath:indexPath];
        return cell;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        HighlightTableViewCell *hlCell = nil;
        hlCell = (HighlightTableViewCell*)[tableView dequeueReusableCellWithIdentifier:searchIdentifier];
        
        if (hlCell == nil) {
            hlCell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:searchIdentifier];
            
            hlCell.autoresizesSubviews = YES;
        }
        
        if (indexPath.row == 0) {
            
            hlCell.highlightLabel.searchString = nil;
            
            if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
            {
                hlCell.highlightLabel.text = [NSString stringWithFormat:@"Use \"%@\"",self.searchString];
            }
            
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
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self handleUpdatedSearchText:searchText];
}


- (void)handleUpdatedSearchText:(NSString *)searchText
{
    self.trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.searchString isEqualToString:self.trimmedString])
    {
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
