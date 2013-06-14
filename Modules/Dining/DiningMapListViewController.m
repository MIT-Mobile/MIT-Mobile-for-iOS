#import "DiningMapListViewController.h"
#import "DiningHallMenuViewController.h"
#import "DiningRetailInfoViewController.h"
#import "DiningData.h"
#import "DiningLink.h"
#import "MITSingleWebViewCellTableViewController.h"
#import "DiningLocationCell.h"
#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "MITTabBar.h"
#import "FacilitiesLocationData.h"
#import "FacilitiesLocation.h"
#import "DiningModule.h"
#import "CoreDataManager.h"
#import "HouseVenue.h"
#import "RetailVenue.h"
#import "VenueLocation.h"
#import "UIImage+PDF.h"
#import "UIImageView+WebCache.h"
#import "MGSMapView.h"
#import "MGSLayer.h"
#import "MGSAnnotation.h"
#import "MGSSimpleAnnotation.h"

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, MGSMapViewDelegate, MGSLayerDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UIView * tabContainerView;
@property (nonatomic, strong) IBOutlet UIButton * houseButton;
@property (nonatomic, strong) IBOutlet UIButton * retailButton;
@property (nonatomic, strong) IBOutlet MITTabBar * tabBar;
@property (nonatomic, strong) IBOutlet UIView *mapContainer;
@property (nonatomic, strong) MGSMapView *mapView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowingMap;
@property (nonatomic, assign) BOOL isShowingHouseDining;

@property (nonatomic, assign) NSInteger announcementSectionIndex;
@property (nonatomic, assign) NSInteger venuesSectionIndex;
@property (nonatomic, assign) NSInteger resourcesSectionIndex;
@property (nonatomic, assign) NSInteger houseSectionCount;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation DiningMapListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
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
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Dining";

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:MITImageNameBackground]];
    self.listView.backgroundColor = [UIColor colorWithHexString:@"#d4d6db"];
    
    [[DiningData sharedData] reload];
    
    UIBarButtonItem *mapListToggle = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapList:)];
    self.navigationItem.rightBarButtonItem = mapListToggle;
    
    [self.houseButton addTarget:self action:@selector(tabBarDidChange:) forControlEvents:UIControlEventTouchUpInside];
    [self.houseButton sendActionsForControlEvents:UIControlEventTouchUpInside]; // press this button initially
    [self.retailButton addTarget:self action:@selector(tabBarDidChange:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addTabWithTitle:@"House Dining"];
    [self addTabWithTitle:@"Retail"];
    self.tabBar.selectedSegmentIndex = 0;
    
    self.listView.backgroundView = nil;
    
    [self layoutListState];
}

- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *selectedIndexPath = [self.listView indexPathForSelectedRow];
    [self.listView deselectRowAtIndexPath:selectedIndexPath animated:animated];
}

- (void) addTabWithTitle:(NSString *)title
{
    NSInteger index = [self.tabBar.items count];
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:title image:nil tag:index];
    [self.tabBar insertSegmentWithItem:item atIndex:index animated:NO];
}

- (void) tabBarDidChange:(UIButton *) sender
{
    if (!sender.selected) {
        if ([sender isEqual:self.houseButton]) {
            [self fetchHouseResults];
            self.isShowingHouseDining = YES;
            self.retailButton.selected = NO;
        } else {
            [self fetchRetailResults];
            self.isShowingHouseDining = NO;
            self.houseButton.selected = NO;
        }
        sender.selected = YES;
        
        if ([self isShowingMap]) {
            [self annotateVenues];
        } else {
            [self.listView reloadData];
        }
    }
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if (!self.isShowingMap && self.mapView) {
        [self.mapView removeFromSuperview];
        self.mapView = nil;
    }
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
    self.mapContainer.userInteractionEnabled = NO;
    self.mapContainer.alpha = 0;
    self.listView.frame = CGRectMake(0, CGRectGetMaxY(self.tabContainerView.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.tabContainerView.frame));
    [self setButtonBackgroundsForListState];
}

- (void) layoutMapState
{
    self.tabContainerView.center = CGPointMake(self.view.center.x, CGRectGetHeight(self.view.bounds) - 25);
    
    self.listView.center = CGPointMake(self.listView.center.x, self.listView.center.y + CGRectGetHeight(self.listView.bounds));
    
    self.mapContainer.alpha = 1;
    self.mapContainer.userInteractionEnabled = YES;
    self.mapContainer.hidden = NO;
    self.mapContainer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    if (!self.mapView) {
        self.mapView = [[MGSMapView alloc] initWithFrame:self.mapContainer.bounds];
        self.mapView.delegate = self;
        [self.mapContainer addSubview:self.mapView];
    }
    [self setButtonBackgroundsForMapState];
    [self annotateVenues];
}

- (void) setButtonBackgroundsForListState
{
    CGSize pdfSize = CGSizeMake(160, 55);
    [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
    
    [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
    
}

- (void) setButtonBackgroundsForMapState
{
    CGSize pdfSize = CGSizeMake(160, 55);
    [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-house-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-house-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.houseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-house-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
    
    [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-retail-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-retail-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.retailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-retail-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
}

#pragma mark - Core Data

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

- (void)fetchHouseResults {
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
    
    [self.fetchedResultsController performFetch:nil];
}

- (void)fetchRetailResults {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RetailVenue"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *groupDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortableBuilding"
                                                                   ascending:YES];
    NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"shortName"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[groupDescriptor, nameDescriptor]];
    
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext
                                          sectionNameKeyPath:@"sortableBuilding"
                                                   cacheName:nil];
    self.fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![self showingHouseDining]) {
        return [[self.fetchedResultsController sections][section] numberOfObjects];
    }
    
    if (section == _announcementSectionIndex) {
        return 1;
    } else if (section == _resourcesSectionIndex) {
        return [[[DiningData sharedData] links] count]; // No meal plan balances for now. Let's wait until the API is better tested.
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
    if ([self showingHouseDining]) {
        return _houseSectionCount;
    } else {
        return [[self.fetchedResultsController sections] count];
    }
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if ([self showingHouseDining]) {
        if (indexPath.section == _announcementSectionIndex) {
            [self configureAnnouncementCell:cell];
        } else if (indexPath.section == _resourcesSectionIndex) {
//            if (indexPath.row == 0) {
//                [self configureBalanceCell:cell];
//            } else {
                [self configureLinkCell:cell atIndexPath:indexPath];
//            }
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
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)configureAnnouncementCell:(UITableViewCell *)cell {
    cell.textLabel.text = [[[DiningData sharedData] announcementsHTML] stringByStrippingTags];
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
    DiningLink *link = [[[DiningData sharedData] links] objectAtIndex:indexPath.row];
    cell.textLabel.text = link.name;
}

- (void)configureHouseVenueCell:(DiningLocationCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    HouseVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.titleLabel.text = venue.name;
    cell.subtitleLabel.text = [venue hoursToday];
    cell.statusOpen = [venue isOpenNow];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    __weak DiningLocationCell *weakCell = cell;
    [cell.imageView setImageWithURL:[NSURL URLWithString:venue.iconURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [weakCell setNeedsLayout];
    }];
}

- (void)configureRetailVenueCell:(DiningLocationCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    RetailVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.titleLabel.text = venue.name;
    cell.subtitleLabel.text = [venue hoursToday];
    cell.statusOpen = [venue isOpenNow];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    NSURL *iconURL = (venue.iconURL) ? [NSURL URLWithString:venue.iconURL] : nil;
    __weak DiningLocationCell *weakCell = cell;
    [cell.imageView setImageWithURL:iconURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [weakCell setNeedsLayout];
    }];
}

#pragma mark - UITableViewDelegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self showingHouseDining]) {
        RetailVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        DiningRetailInfoViewController *detailVC = [[DiningRetailInfoViewController alloc] init];
        detailVC.venue = venue;
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
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
//        if (indexPath.row == 0) {
//            // do meal plan balance (log in to Touchstone if not logged in, do nothing otherwise)
//        } else {
        // handle links
        DiningLink *link = [[[DiningData sharedData] links] objectAtIndex:indexPath.row];
        NSURL *url = [NSURL URLWithString:link.url];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
//        }
    } else if (indexPath.section == _announcementSectionIndex) {
        MITSingleWebViewCellTableViewController *vc = [[MITSingleWebViewCellTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.webViewInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        vc.htmlContent = [[DiningData sharedData] announcementsHTML];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self showingHouseDining]) {
        RetailVenue *venue = [self.fetchedResultsController objectAtIndexPath:indexPath];
        return [DiningLocationCell heightForRowWithTitle:venue.name subtitle:@"9am - 5pm"];
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
    label.font = [UIFont boldSystemFontOfSize:14];
    
    label.text = [self titleForHeaderInSection:section];
    
    [view addSubview:label];
    
    return view;
}

- (NSString *) titleForHeaderInSection:(NSInteger)section // not the UITableViewDataSource method.
{
    if (![self showingHouseDining]) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        RetailVenue *venue = [sectionInfo objects][0];
        NSString *building = venue.building;
        // This may need to have an `updated` block in case locations aren't actually loaded yet.
        NSArray *matches = [[FacilitiesLocationData sharedData] locationsWithNumber:building updated:nil];
        if ([matches count] > 0) {
            building = [building stringByAppendingFormat:@" - %@", ((FacilitiesLocation *)matches[0]).name];
        }
        return building;
    }
    
    NSString *announcement = [[DiningData sharedData] announcementsHTML];
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
    if ([self showingHouseDining] && [[DiningData sharedData] announcementsHTML] && section == 0) {
        return 0;
    }
    
    return 25;
}

#pragma mark - MapView Methods

- (void) annotateVenues
{
    NSArray *venues = [self.fetchedResultsController fetchedObjects];
    
    [self.mapView removeLayer:[[self.mapView mapLayers] lastObject]]; // need to remove previously added layer before adding anything new or else will cause crash
    MGSLayer * houseLayer = [[MGSLayer alloc] initWithName:@"house.layer"];
    houseLayer.delegate = self;
    [houseLayer addAnnotationsFromArray:venues];
    
    [self.mapView addLayer:houseLayer];
    [self.mapView setNeedsDisplay];
}

#pragma mark -MGSMapView Delegate
- (void)mapView:(MGSMapView*)mapView calloutDidReceiveTapForAnnotation:(id<MGSAnnotation>)annotation
{
    if ([annotation isKindOfClass:[HouseVenue class]]) {
        DiningHallMenuViewController *detailVC = [[DiningHallMenuViewController alloc] init];
        detailVC.venue = (HouseVenue *)annotation;
        [self.navigationController pushViewController:detailVC animated:YES];
    } else if ([annotation isKindOfClass:[RetailVenue class]]) {
        DiningRetailInfoViewController *detailVC = [[DiningRetailInfoViewController alloc] init];
        detailVC.venue = (RetailVenue *)annotation;
        [self.navigationController pushViewController:detailVC animated:YES];
    }
}

@end
