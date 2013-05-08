#import "DiningMapListViewController.h"
#import "DiningHallMenuViewController.h"
#import "DiningRetailInfoViewController.h"
#import "DiningLocationCell.h"
#import "UIKit+MITAdditions.h"
#import "MITTabBar.h"
#import "FacilitiesLocationData.h"
#import "DiningModule.h"
#import "DiningData.h"
#import "CoreDataManager.h"
#import "HouseVenue.h"
#import "VenueLocation.h"
#import "UIImage+PDF.h"

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UIView * tabContainerView;
@property (nonatomic, strong) IBOutlet UIButton * houseButton;
@property (nonatomic, strong) IBOutlet UIButton * retailButton;
@property (nonatomic, strong) IBOutlet MITTabBar * tabBar;
@property (nonatomic, strong) IBOutlet MGSMapView *mapView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowingMap;
@property (nonatomic, assign) BOOL isShowingHouseDining;

@property (nonatomic, assign) NSInteger announcementSectionIndex;
@property (nonatomic, assign) NSInteger venuesSectionIndex;
@property (nonatomic, assign) NSInteger resourcesSectionIndex;
@property (nonatomic, assign) NSInteger houseSectionCount;

@property (nonatomic, strong) NSDictionary * retailVenues;

@property (nonatomic, strong) NSDictionary * sampleData;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation DiningMapListViewController

- (NSString *) debugAnnouncement
{
//    return nil;
    return @"ENROLL in the spring 2013 Meal Plan Program today! Or else you should be worried.";
}

- (NSArray *) debugHouseDiningData
{
    return [NSArray arrayWithObjects:@"Baker", @"The Howard Dining Hall at Maseeh", @"McCormick", @"Next", @"Simmons", nil];
}

- (NSArray *) debugRetailDiningData
{
    return [NSArray arrayWithObjects:@"Anna's Taqueria", @"Cafe Spice", @"Cambridge Grill", @"Dunkin Donuts", @"LaVerde's Market", nil];
}

- (NSArray *) debugSubtitleData
{
    return @[@"12pm - 4pm", @"8pm - 4am, 9am - 12pm", @"10am - 2pm, 4pm - 7pm", @"8am - 2pm", @"7am - 9am, 2pm - 8pm, 5pm - 9pm"];
}

- (NSArray *) debugResourceData
{
    return @[@"Comments for MIT Dining", @"Food to Go", @"Full MIT Dining Website"];
}

- (NSArray *) currentDiningData
{
    NSArray *data = ([self.tabBar selectedSegmentIndex] == 0)? [self debugHouseDiningData ]: [self debugRetailDiningData];
    return data;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[DiningData sharedData] loadDebugData];
        
        bool hasAnnouncement = true;
        
        if (hasAnnouncement) {
            _announcementSectionIndex = 0;
            _venuesSectionIndex = 1;
            _resourcesSectionIndex = 2;
            _houseSectionCount = 3;
        } else {
            _announcementSectionIndex = -1;
            _venuesSectionIndex = 0;
            _resourcesSectionIndex = 1;
            _houseSectionCount = 2;
        }
        
        [self.fetchedResultsController performFetch:nil];
        
        
        self.sampleData = [DiningModule loadSampleDataFromFile];
        
        [self deriveRetailSections];
    }
    return self;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    _managedObjectContext.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
    _managedObjectContext.undoManager = nil;
    _managedObjectContext.stalenessInterval = 0;
    
    return _managedObjectContext;
}

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"HouseVenue"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"shortName"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

- (void) deriveRetailSections
{
    // Uses data from FacilitiesLocationData to get formal building names
    
    NSArray * buildingLocations = [[FacilitiesLocationData sharedData] locationsInCategory:@"building"];
    
    NSArray * retailLocations = self.sampleData[@"venues"][@"retail"];
    NSMutableDictionary *tempBuildings = [NSMutableDictionary dictionary];
    for (NSDictionary *venue in retailLocations) {
        NSString *buildingNumber = venue[@"location"][@"mit_building"];
        NSArray * results = [buildingLocations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"number == %@", buildingNumber]];
       
        // derive the section header name
        NSString * sectionKey = @"Other";
        if ([results count] == 1) {
            NSString * buildingName = [[results lastObject] name];
            sectionKey = [NSString stringWithFormat:@"%@ - %@", buildingNumber, buildingName];

        } else if ([results count] == 0) {
            // need to handle if building is not found
            
        }
        
        // insert venue into correct section array
        if (tempBuildings[sectionKey]) {
            // either at end of section array
            NSMutableArray *venueArray = [tempBuildings[sectionKey] mutableCopy];
            [venueArray addObject:venue];
            tempBuildings[sectionKey] = venueArray;
            
        } else {
            // or in new section array
            tempBuildings[sectionKey] = @[venue];
        }
    }
    
    self.retailVenues = tempBuildings;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Dining";

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    
    UIBarButtonItem *mapListToggle = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapList:)];
    self.navigationItem.rightBarButtonItem = mapListToggle;
    
//    [self.tabBar addTarget:self action:@selector(tabBarDidChange) forControlEvents:UIControlEventValueChanged];
    
    {
        CGSize pdfSize = CGSizeMake(160, 55);
        [self.houseButton addTarget:self action:@selector(tabBarDidChange:) forControlEvents:UIControlEventTouchUpInside];
        [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
        [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
        [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
        [self.houseButton sendActionsForControlEvents:UIControlEventTouchUpInside]; // press this button initially
        
        [self.retailButton addTarget:self action:@selector(tabBarDidChange:) forControlEvents:UIControlEventTouchUpInside];
        [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
        [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
        [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
    }
    
    
    [self addTabWithTitle:@"House Dining"];
    [self addTabWithTitle:@"Retail"];
    self.tabBar.selectedSegmentIndex = 0;
    
    self.listView.backgroundView = nil;
    
    [self layoutListState];
}

- (void) addTabWithTitle:(NSString *)title
{
    NSInteger index = [self.tabBar.items count];
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:title image:nil tag:index];
    [self.tabBar insertSegmentWithItem:item atIndex:index animated:NO];
    
}

- (void) tabBarDidChange:(UIButton *) sender
{
    if ([sender isEqual:self.houseButton]) {
        self.isShowingHouseDining = YES;
        self.retailButton.selected = NO;
    } else {
        self.isShowingHouseDining = NO;
        self.houseButton.selected = NO;
    }
    sender.selected = YES;
    
    [self.listView reloadData];
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) toggleMapList:(id)sender
{
    if (!self.isAnimating) {
        NSLog(@"Toggle the Map List");
        self.navigationItem.rightBarButtonItem.title = (self.isShowingMap)? @"Map" : @"List";
        
        if (self.isShowingMap) {
            // animate to the list
            self.listView.center = CGPointMake(self.view.center.x, self.view.center.y + CGRectGetHeight(self.view.bounds));
            [UIView animateWithDuration:0.4f animations:^{
                [self layoutListState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
            
        } else {
            // animate to the map
            [UIView animateWithDuration:0.4f animations:^{
                [self layoutMapState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
        }
        // toggle boolean flag 
        self.isShowingMap = !self.isShowingMap;
    }
}

- (BOOL) showingHouseDining
{
    return self.isShowingHouseDining;
}

#pragma mark - View layout

- (void) layoutListState
{
    self.tabContainerView.center = CGPointMake(self.view.center.x, 25);
    self.mapView.userInteractionEnabled = NO;
    self.mapView.alpha = 0;
    self.listView.frame = CGRectMake(0, CGRectGetMaxY(self.tabContainerView.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.tabContainerView.frame));
    
}

- (void) layoutMapState
{
    self.tabContainerView.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 25);
    
    self.listView.center = CGPointMake(self.listView.center.x, self.listView.center.y + CGRectGetHeight(self.listView.bounds));
    
    self.mapView.alpha = 1;
    self.mapView.userInteractionEnabled = YES;
    self.mapView.hidden = NO;
    self.mapView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![self showingHouseDining]) {
        NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:section];
        return [self.retailVenues[sectionKey] count];
    }
    
    if (section == _announcementSectionIndex) {
        return 1;
    } else if (section == _resourcesSectionIndex) {
        return [[self debugResourceData] count] + 1;
    } else {
        NSArray *sections = [self.fetchedResultsController sections];
        if ([sections count] > 0) {
            id<NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:0];
            return [sectionInfo numberOfObjects];
        }
    }
    return 0;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if (![self showingHouseDining]) {
//        return [[self.fetchedResultsController sections] count] + extraHouseSections;
        return [[self.retailVenues allKeys] count];
    }

    return _houseSectionCount;
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if ([self showingHouseDining]) {
        if (indexPath.section == _announcementSectionIndex) {
            [self configureAnnouncementCell:cell];
        } else if (indexPath.section == _resourcesSectionIndex) {
            if (indexPath.row == 0) {
                [self configureBalanceCell:cell];
            } else {
                [self configureLinkCell:cell atIndexPath:indexPath];
            }
        } else {
            [self configureHouseVenueCell:(DiningLocationCell *)cell atIndexPath:indexPath];
        }
    } else {
        [self configureRetailVenueCell:(DiningLocationCell *)cell atIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if ([self showingHouseDining] && indexPath.section != _venuesSectionIndex) {
        if (indexPath.section != _resourcesSectionIndex && indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"subtitleCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"subtitleCell"];
            }
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"defaultCell"];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultCell"];
            }
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
        if (!cell) {
            cell = [[DiningLocationCell alloc] initWithReuseIdentifier:@"locationCell"];
        }
    }
    
    cell.backgroundColor = [UIColor whiteColor];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showingHouseDining] && indexPath.section == _announcementSectionIndex) {
        // set announcement background color to yellow color
        cell.backgroundColor = [UIColor colorWithHexString:@"#FFEF8A"];
    }
}

- (void)configureAnnouncementCell:(UITableViewCell *)cell {
    cell.textLabel.text = [self debugAnnouncement];
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureBalanceCell:(UITableViewCell *)cell {
    [cell applyStandardFonts];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewSecure];
    cell.textLabel.text = @"Meal Plan Balance";
    cell.detailTextLabel.text = @"Log in to see balance";
}

- (void)configureLinkCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [cell applyStandardFonts];
    cell.accessoryView = [UIImageView accessoryViewWithMITType:MITAccessoryViewExternal];
    cell.textLabel.text = [[self debugResourceData] objectAtIndex:indexPath.row - 1];
}

- (void)configureHouseVenueCell:(DiningLocationCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    HouseVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.titleLabel.text = venue.name;
    cell.subtitleLabel.text = [venue hoursToday];
    cell.statusOpen = [venue isOpenNow];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:@"icons/home-about.png"];
}

- (void)configureRetailVenueCell:(DiningLocationCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
    NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
    
    cell.titleLabel.text = venueData[@"name"];
    cell.subtitleLabel.text = [self debugSubtitleData][indexPath.row%[[self debugSubtitleData] count]];
//    cell.statusOpen = indexPath.row % 2 == 0;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:@"icons/home-map.png"];
}

#pragma mark Configure Retail Cell
- (UITableViewCell *) tableView:(UITableView *)tableView retailDiningLocationCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DiningLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
    if (!cell) {
        cell = [[DiningLocationCell alloc] initWithReuseIdentifier:@"locationCell"];
    }
    
    
    
    NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
    NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
    
    cell.titleLabel.text = venueData[@"name"];
    cell.subtitleLabel.text = [self debugSubtitleData][indexPath.row%[[self debugSubtitleData] count]];
    cell.statusOpen = indexPath.row % 2 == 0;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:@"icons/home-map.png"];
    
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (![self showingHouseDining]) {
        NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
        NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
        
        DiningRetailInfoViewController *detailVC = [[DiningRetailInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
        detailVC.venueData = venueData;
        [self.navigationController pushViewController:detailVC animated:YES];
        return;
    }
    
    if (indexPath.section == _venuesSectionIndex) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        HouseVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        DiningHallMenuViewController *detailVC = [[DiningHallMenuViewController alloc] init];
        detailVC.venue = venue;
        [self.navigationController pushViewController:detailVC animated:YES];
    } else if (indexPath.section == _resourcesSectionIndex) {
        if (indexPath.row == 0) {
            // do meal plan balance (log in to Touchstone if not logged in, do nothing otherwise)
        } else {
            // handle links
        }
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self showingHouseDining]) {
        NSString *sectionKey = [[self.retailVenues allKeys] objectAtIndex:indexPath.section];
        NSDictionary *venueData = self.retailVenues[sectionKey][indexPath.row];
        return [DiningLocationCell heightForRowWithTitle:venueData[@"name"] subtitle:[self debugSubtitleData][indexPath.row%[[self debugSubtitleData] count]]];
    }
    
    if (indexPath.section == _venuesSectionIndex) {
        indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
        HouseVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
        return [DiningLocationCell heightForRowWithTitle:venue.name subtitle:[venue hoursToday]];
    }
    
    return 44;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIColor *bc = [UIColor colorWithHexString:@"#718fb1"];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.listView.bounds), 25)];
    view.backgroundColor = bc;
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(view.bounds) - 10 , 25)];
    label.backgroundColor = bc;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    
    label.text = [self titleForHeaderInSection:section];
    
    [view addSubview:label];
    
    return view;
}

- (NSString *) titleForHeaderInSection:(NSInteger)section // not the UITableViewDataSource method.
{
    if (![self showingHouseDining]) {
        return [[self.retailVenues allKeys] objectAtIndex:section];
    }
    
    NSString *announcement = [self debugAnnouncement];
    if (announcement && section == 0) {
        return nil;
    } else if((!announcement && section == 0) || (announcement && section == 1)) {
        return @"Venues";
    } else if ((!announcement && section == 1)|| section == 2) {
        return @"Resources";
    }
    
    return nil;
}



- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self showingHouseDining] && [self debugAnnouncement] && section == 0) {
        return 0;
    }
    
    return 25;
}



#pragma mark - MapView Methods


@end

