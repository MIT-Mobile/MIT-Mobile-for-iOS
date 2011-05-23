#import <CoreLocation/CoreLocation.h>

#import "FacilitiesLocationDataViewController.h"

#import "FacilitiesLocationData.h"
#import "HighlightTableViewCell.h"
#import "MITLogging.h"
#import "MITLoadingActivityView.h"
#import "UIKit+MITAdditions.h"

@interface FacilitiesLocationDataViewController ()
@end

@implementation FacilitiesLocationDataViewController
@synthesize tableView = _tableView;
@synthesize loadingView = _loadingView;

@synthesize locationData = _locationData;
@synthesize filteredData = _filteredData;
@synthesize searchString = _searchString;

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
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    self.cachedData = nil;
    [super didReceiveMemoryWarning];
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
        loadingView.backgroundColor = [UIColor redColor];
        
        self.loadingView = loadingView;
        [mainView insertSubview:loadingView
                   aboveSubview:self.tableView];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:nil
                                                                  action:nil];
    self.navigationItem.backBarButtonItem = [backButton autorelease];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.cachedData = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark -
#pragma mark Public Methods
- (NSArray*)dataForMainTableView {
    return [NSArray array];
}

- (NSArray*)resultsForSearchString:(NSString*)searchText {
    return [NSArray array];
}

- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath {
    if ([self.cachedData count] >= indexPath.row) {
        cell.textLabel.text = [[self.cachedData objectAtIndex:indexPath.row] description];
    }
}


- (void)configureSearchCell:(HighlightTableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath {
    cell.highlightLabel.searchString = self.searchString;
    
    if ([self.cachedData count] >= indexPath.row) {
        cell.highlightLabel.text = [[self.cachedData objectAtIndex:indexPath.row] description];
    }
}

#pragma mark -
#pragma mark Dynamic Setters/Getters
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
    if (_filteredData == nil) {
        [self setFilteredData:[self resultsForSearchString:self.searchString]];
    }
    
    return _filteredData;
}

#pragma mark -
#pragma mark UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return [self.cachedData count];
    } else {
        return [self.filteredData count] + 1;
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
            hlCell.highlightLabel.text = [NSString stringWithFormat:@"Use: %@",self.searchString];
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

#pragma mark -
#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchString = searchText;
    self.filteredData = nil;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchDisplayController setActive:NO
                                   animated:YES];
}

@end
