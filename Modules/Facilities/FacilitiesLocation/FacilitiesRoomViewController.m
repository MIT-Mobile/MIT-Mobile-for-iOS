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
#import "MITBuildingServicesReportForm.h"

@interface FacilitiesRoomViewController () <UITableViewDataSource,UITableViewDelegate,UISearchResultsUpdating>
@property (nonatomic,strong) UISearchController *strongSearchDisplayController;
@property (nonatomic,strong) MITLoadingActivityView* loadingView;
@property (nonatomic,strong) FacilitiesLocationData* locationData;
@property (nonatomic,strong) NSPredicate* filterPredicate;

@property (nonatomic,copy) NSArray* cachedData;
@property (nonatomic,copy) NSArray* filteredData;
@property (nonatomic,copy) NSString* searchString;
@property (nonatomic,copy) NSString *trimmedString;
@property (nonatomic,strong) id observerToken;

@property (nonatomic, strong) NSMutableDictionary *floors;

@property (nonatomic, assign) BOOL hasZeroFloor;
@property (nonatomic, assign) BOOL searching;

- (NSArray*)dataForMainTableView;
- (void)configureMainTableCell:(UITableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
- (void)configureSearchCell:(HighlightTableViewCell*)cell forIndexPath:(NSIndexPath*)indexPath;
@end

@implementation FacilitiesRoomViewController
- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"Where is it?";
        self.locationData = [FacilitiesLocationData sharedData];
    }
    return self;
}

#pragma mark - View lifecycle
- (void)loadView {
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    
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
        
        UITableView *tableView = [[UITableView alloc] initWithFrame: tableRect style:UITableViewStylePlain];
        tableView.backgroundView = nil;
        tableView.backgroundColor = [UIColor clearColor];
        
        tableView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
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
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        self.definesPresentationContext = YES;
        self.strongSearchDisplayController = searchController;
        
        // while we still need to initialize searchController for both iPhone and iPad,
        // we only need add search bar to the view for the iPhone case
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone )
        {
            [searchController.searchBar sizeToFit];
            searchBarFrame = searchController.searchBar.frame;
            self.tableView.tableHeaderView = searchController.searchBar;
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
                                             selector:@selector(customRoomTextDidChange:)
                                                 name:MITBuildingServicesLocationCustomTextNotification
                                               object:nil];
    
    if (self.observerToken == nil) {
        __weak FacilitiesRoomViewController *weakSelf = self;
        self.observerToken = [self.locationData addUpdateObserver:^(NSString *notification, BOOL updated, id userData) {
            FacilitiesRoomViewController *blockSelf = weakSelf;
            if (blockSelf) {
                if ((notification == nil) || [userData isEqualToString:FacilitiesRoomsKey]) {
                    [blockSelf.loadingView removeFromSuperview];
                    blockSelf.loadingView = nil;
                    blockSelf.tableView.hidden = NO;
                    
                    if ((blockSelf.cachedData == nil) || updated) {
                        blockSelf.cachedData = nil;
                        [blockSelf.tableView reloadData];
                    }
                    
                    if ([blockSelf.strongSearchDisplayController isActive] && ((blockSelf.filteredData == nil) || updated)) {
                        blockSelf.filteredData = nil;
                        [blockSelf.tableView reloadData];
                    }
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
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
    
    [self populateFloorsWithRooms:data];
    
    return data;
}

- (void)populateFloorsWithRooms:(NSArray *)data
{
    self.floors = [NSMutableDictionary new];
    for( FacilitiesRoom *room in data )
    {
        if( !self.hasZeroFloor && [room.floor isEqualToString:@"0"] )
        {
            self.hasZeroFloor = YES;
        }
        
        NSMutableArray *rooms = self.floors[room.floor];
        if( rooms == nil )
        {
            rooms = [NSMutableArray new];
        }
        
        [rooms addObject:room];
        [self.floors setObject:rooms forKey:room.floor];
    }
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
    if( indexPath.section == 0 && indexPath.row == 0 )
    {
        cell.textLabel.text = @"Outside";
    }
    else if( indexPath.section == 0 && indexPath.row == 1 )
    {
        cell.textLabel.text = @"Inside";
    }
    else
    {
        cell.textLabel.text = [[self roomAtIndexPath:indexPath] displayString];
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


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FacilitiesRoom *room = nil;
    NSString *altName = nil;
    
    if (!self.searching)
    {
        if( indexPath.section == 0 && indexPath.row == 0 )
        {
            altName = @"Outside";
        }
        else if( indexPath.section == 0 && indexPath.row == 1 )
        {
            altName = @"Inside";
        }
        else
        {
            room = [self roomAtIndexPath:indexPath];
        }
    }
    else
    {
        if (indexPath.row == 0) {
            altName = self.searchString;
        } else {
            room = self.filteredData[indexPath.row-1];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [MITBuildingServicesReportForm sharedServiceReport].room = room;
    [MITBuildingServicesReportForm sharedServiceReport].roomAltName = altName;
    
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

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *allKeys = [self.floors allKeys];
    
    NSArray *sortedFloors = [allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *room1 = (NSString *)obj1;
        NSString *room2 = (NSString *)obj2;
        
        return [room1 caseInsensitiveCompare:room2];
    }];
    
    int counter = 0;
    
    NSMutableArray *mSortedFloors = [NSMutableArray array];
    for( NSString *floor in sortedFloors )
    {
        [mSortedFloors addObject:floor];
        
        if( counter < [sortedFloors count] - 1 )
        {
            [mSortedFloors addObject:@"•"];
        }
        
        counter++;
    }
    
    return mSortedFloors;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return 1 + index/2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if( section == 0 )
    {
        return nil;
    }
    
    return [NSString stringWithFormat:@"FLOOR %ld", (long)[self floorBasedOnSection:section]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.searching)
    {
        if( self.cachedData == nil )
        {
            return 1;
        }
        
        return 1 + [self.floors count];
    }
    else
    {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.searching)
    {
        if ((self.cachedData == nil) || ([self.cachedData count] == 0))
        {
            return 2;
        }
        else
        {
            return (section == 0) ? 2 : [[self roomsOnFloor:section] count];
        } 
    }
    else
    {
        return ([self.trimmedString length] > 0) ? [self.filteredData count] + 1 : 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *facilitiesIdentifier = @"facilitiesCell";
    static NSString *searchIdentifier = @"searchCell";
    
    if (!self.searching)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:facilitiesIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:facilitiesIdentifier];
        }
        
        [self configureMainTableCell:cell forIndexPath:indexPath];
        
        return cell;
    }
    else
    {
        HighlightTableViewCell *hlCell = (HighlightTableViewCell*)[tableView dequeueReusableCellWithIdentifier:searchIdentifier];
        
        if (hlCell == nil)
        {
            hlCell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:searchIdentifier];
            
            hlCell.autoresizesSubviews = YES;
        }
        
        if (indexPath.row == 0)
        {
            hlCell.highlightLabel.searchString = nil;
            hlCell.highlightLabel.text = [NSString stringWithFormat:@"Use \"%@\"",self.searchString];
        }
        else
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(indexPath.row-1) inSection:indexPath.section];
            [self configureSearchCell:hlCell forIndexPath:path];
        }
        
        return hlCell;
    }
}

#pragma mark - notifications

// on iPad manually set searchText and add searchResultsTableView to the view hierarchy
// in order to show the filtered list.
- (void)customRoomTextDidChange:(NSNotification *)senderNotification
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
    
    [MITBuildingServicesReportForm sharedServiceReport].room = nil;
    [MITBuildingServicesReportForm sharedServiceReport].roomAltName = self.searchString;
    
    self.searching = customLocationText.length == 0 ? NO : YES;
    [self.tableView reloadData];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self handleUpdatedSearchText:searchController.searchBar.text];
}

- (void)handleUpdatedSearchText:(NSString *)searchText
{
    self.trimmedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self.searchString isEqualToString:self.trimmedString])
    {
        self.searchString = ([self.trimmedString length] > 0) ? self.trimmedString : nil;
        self.filteredData = nil;
    }
    
    self.searching = searchText.length == 0 ? NO : YES;
    [self.tableView reloadData];

}

#pragma mark - utils

- (FacilitiesRoom *)roomAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *floorStr = [NSString stringWithFormat:@"%ld", (long)[self floorBasedOnSection:indexPath.section]];
    
    NSArray *rooms = self.floors[floorStr];
    
    return rooms[indexPath.row];
}

- (NSArray *)roomsOnFloor:(NSInteger)floor
{
    NSString *floorStr = [NSString stringWithFormat:@"%ld", (long)[self floorBasedOnSection:floor]];
    
    return self.floors[floorStr];
}

- (NSInteger)floorBasedOnSection:(NSInteger)section
{
    return self.hasZeroFloor ? (section - 1) : section;
}

@end
