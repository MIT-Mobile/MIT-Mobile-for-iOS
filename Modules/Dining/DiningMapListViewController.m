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
#import "UIScrollView+SVPullToRefresh.h"

#import "MITTiledMapView.h"
#import "MITDiningPlace.h"
#import "MITMapPlaceAnnotationView.h"

static NSString * const kMITMapPlaceAnnotationViewIdentifier = @"MITMapPlaceAnnotationView";

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UIView * listTabContainerView;
@property (nonatomic, strong) IBOutlet UIButton * listHouseButton;
@property (nonatomic, strong) IBOutlet UIButton * listRetailButton;
@property (nonatomic, strong) IBOutlet UIView * mapSegmentContainerView;
@property (nonatomic, strong) IBOutlet UIButton * mapHouseButton;
@property (nonatomic, strong) IBOutlet UIButton * mapRetailButton;
@property (nonatomic, strong) IBOutlet UIView *mapContainer;
@property (nonatomic, strong) MITTiledMapView *tiledMapView;
@property (nonatomic, readonly) MKMapView *mapView;
@property (nonatomic, getter = isAnimating) BOOL animating;
@property (nonatomic, getter = isShowingMap) BOOL showingMap;
@property (nonatomic, getter = isShowingHouseDining) BOOL showingHouseDining;
@property (nonatomic, getter = isLoading) BOOL loading;

@property (nonatomic, assign) NSInteger announcementSectionIndex;
@property (nonatomic, assign) NSInteger venuesSectionIndex;
@property (nonatomic, assign) NSInteger resourcesSectionIndex;
@property (nonatomic, assign) NSInteger houseSectionCount;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSArray *favoritedRetailVenues;

@property (strong, nonatomic) NSArray *places;
@property (nonatomic) BOOL shouldRefreshAnnotationsOnNextMapRegionChange;
@end

@implementation DiningMapListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        [self updateTableViewSectionIndices];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Dining";

    self.view.backgroundColor = [UIColor mit_backgroundColor];
    
    UIBarButtonItem *mapListToggle = [[UIBarButtonItem alloc] initWithTitle:@"Map" style:UIBarButtonItemStylePlain target:self action:@selector(toggleMapList:)];
    self.navigationItem.rightBarButtonItem = mapListToggle;
    
    // only list buttons work at first
    self.listTabContainerView.userInteractionEnabled = YES;
    self.mapSegmentContainerView.userInteractionEnabled = NO;
    
    // hook up list buttons
    [self.listHouseButton addTarget:self action:@selector(showHouse:) forControlEvents:UIControlEventTouchUpInside];
    [self.listHouseButton sendActionsForControlEvents:UIControlEventTouchUpInside]; // press this button initially
    [self.listRetailButton addTarget:self action:@selector(showRetail:) forControlEvents:UIControlEventTouchUpInside];
    
    // hook up map buttons
    [self.mapHouseButton addTarget:self action:@selector(showHouse:) forControlEvents:UIControlEventTouchUpInside];
    [self.mapHouseButton sendActionsForControlEvents:UIControlEventTouchUpInside]; // press this button initially
    [self.mapRetailButton addTarget:self action:@selector(showRetail:) forControlEvents:UIControlEventTouchUpInside];

    [self setButtonBackgroundsForListState];
    [self setButtonBackgroundsForMapState];
    
    self.listView.backgroundView = nil;
    
    __weak DiningMapListViewController *weakSelf = self;
    [self.listView addPullToRefreshWithActionHandler:^{
        [[SDImageCache sharedImageCache] cleanDisk];
        weakSelf.loading = YES;
        
        [[DiningData sharedData] reloadAndCompleteWithBlock:^ (NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                weakSelf.favoritedRetailVenues = nil;
                [weakSelf updateTableViewSectionIndices];
                
                [weakSelf refreshSelectedTypeOfVenues];
                
                if (error) {
                    [weakSelf.listView.pullToRefreshView setSubtitle:@"Update failed"
                                                            forState:SVPullToRefreshStateAll];
                } else {
                    [weakSelf updatePullToRefreshSubtitle];
                }
                
                
                [UIView animateWithDuration:0.3
                                 animations:^{
                                     [weakSelf.listView.pullToRefreshView stopAnimating];
                                 }
                                 completion:^(BOOL finished) {
                                     weakSelf.loading = NO;
                                 }];
            }];
        }];
    }];
    
    [self.listView.pullToRefreshView setTitle:@"Pull to refresh" forState:SVPullToRefreshStateStopped];
    [self.listView.pullToRefreshView setTitle:@"Release to refresh" forState:SVPullToRefreshStateTriggered];
    [self.listView.pullToRefreshView setTitle:@"Loading..." forState:SVPullToRefreshStateLoading];
    
    [self updatePullToRefreshSubtitle];
    
    [self layoutListState];
    
    [self.listView triggerPullToRefresh];
}

- (void)updatePullToRefreshSubtitle {
    NSDate *date = [[DiningData sharedData] lastUpdated];
    
    if (date) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        
        NSString *dateString = [formatter stringFromDate:date];
        [self.listView.pullToRefreshView setSubtitle:[NSString stringWithFormat:@"Updated %@", dateString]
                                            forState:SVPullToRefreshStateAll];
    } else {
        [self.listView.pullToRefreshView setSubtitle:nil
                                            forState:SVPullToRefreshStateAll];
    }
}

- (void) updateTableViewSectionIndices
{
    BOOL hasAnnouncement = [[[DiningData sharedData] announcementsHTML] length];
    
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

- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *selectedIndexPath = [self.listView indexPathForSelectedRow];
    [self.listView deselectRowAtIndexPath:selectedIndexPath animated:animated];
    self.favoritedRetailVenues = nil;
    [self.listView reloadData];
}

- (void)showHouse:(id)sender {
    if (!self.isLoading  && !self.isShowingHouseDining) {
        self.showingHouseDining = YES;
        [self tabBarDidChange:sender];
    }
}

- (void)showRetail:(id)sender {
    if (!self.isLoading && self.isShowingHouseDining) {
        self.showingHouseDining = NO;
        [self tabBarDidChange:sender];
    }
}

- (void) tabBarDidChange:(UIButton *) sender
{
    self.listHouseButton.selected = self.isShowingHouseDining;
    self.mapHouseButton.selected = self.isShowingHouseDining;
    self.listRetailButton.selected = !self.isShowingHouseDining;
    self.mapRetailButton.selected = !self.isShowingHouseDining;
    [self refreshSelectedTypeOfVenues];
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if (!self.isShowingMap && self.tiledMapView) {
        [self.tiledMapView removeFromSuperview];
        self.tiledMapView = nil;
    }
}

- (void) toggleMapList:(id)sender
{
    if (!self.isLoading && !self.isAnimating) {
        self.navigationItem.rightBarButtonItem.title = (self.isShowingMap)? @"Map" : @"List";
        
        if (self.isShowingMap) {
            [self.listView reloadData];
            // animate to the list
            [UIView animateWithDuration:0.4f animations:^{
                [self layoutListState];
                self.animating = YES;
            } completion:^(BOOL finished) {
                self.animating = NO;
            }];
            
        } else {
            if (!self.tiledMapView) {
                [self setupTiledMapView];
            }
            [self updateMapView];
            // animate to the map
            [UIView animateWithDuration:0.4f animations:^{
                [self layoutMapState];
                self.animating = YES;
            } completion:^(BOOL finished) {
                self.animating = NO;
            }];
        }
        // toggle boolean flag 
        self.showingMap = !self.isShowingMap;
    }
}

- (void)setupTiledMapView
{self.tiledMapView = [[MITTiledMapView alloc] initWithFrame:self.mapContainer.bounds];
    [self.tiledMapView setLeftButtonHidden:NO animated:YES];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.tintColor =self.mapView.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    [self setupMapBoundingBoxAnimated:NO];
    [self.mapContainer addSubview:self.tiledMapView];
}

#pragma mark - Dynamic Properties
- (NSArray*)favoritedRetailVenues
{
    if (_favoritedRetailVenues == nil) {
        _favoritedRetailVenues = [CoreDataManager objectsForEntity:@"RetailVenue"
                                                 matchingPredicate:[NSPredicate predicateWithFormat:@"favorite == YES"]
                                                   sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    }
    
    return _favoritedRetailVenues;
}


#pragma mark - View layout

- (void) layoutListState
{
    CGRect frame = self.listTabContainerView.frame;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        frame.origin = CGPointMake(0.0, 64.0);
    } else {
        frame.origin = CGPointMake(0.0, 0.0);
    }
    self.listTabContainerView.frame = frame;
    
    frame = self.mapSegmentContainerView.frame;
    frame.origin = CGPointMake(0.0, self.listTabContainerView.frame.origin.y + 6);
    self.mapSegmentContainerView.frame = frame;

    self.mapSegmentContainerView.alpha = 0.0;
    self.listTabContainerView.alpha = 1.0;
    self.mapSegmentContainerView.userInteractionEnabled = NO;
    self.listTabContainerView.userInteractionEnabled = YES;

    self.mapContainer.userInteractionEnabled = NO;
    self.mapContainer.alpha = 0;
    self.listView.frame = CGRectMake(0, CGRectGetMaxY(self.listTabContainerView.frame), self.view.bounds.size.width, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.listTabContainerView.frame));
}

- (void) layoutMapState
{
    CGRect frame = self.listTabContainerView.frame;
    frame.origin = CGPointMake(0.0, self.view.bounds.size.height - self.listTabContainerView.frame.size.height - 20 - 4); // 20pt padding + 4pt adjusting for the image size
    self.listTabContainerView.frame = frame;
    
    frame = self.mapSegmentContainerView.frame;
    frame.origin = CGPointMake(0.0, self.listTabContainerView.frame.origin.y + 6);
    self.mapSegmentContainerView.frame = frame;

    self.mapSegmentContainerView.alpha = 1.0;
    self.listTabContainerView.alpha = 0.0;
    self.mapSegmentContainerView.userInteractionEnabled = YES;
    self.listTabContainerView.userInteractionEnabled = NO;

    CGRect listFrame = self.listView.frame;
    listFrame.origin.y = CGRectGetHeight(self.view.bounds);
    self.listView.frame = listFrame;
    
    self.mapContainer.alpha = 1;
    self.mapContainer.userInteractionEnabled = YES;
    self.mapContainer.hidden = NO;
    self.mapContainer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
}

- (void) setButtonBackgroundsForListState
{
    CGSize pdfSize = CGSizeMake(160, 55);
    [self.listHouseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.listHouseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.listHouseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-house-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
    
    [self.listRetailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.listRetailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.listRetailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/tab-retail-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
}

- (void) setButtonBackgroundsForMapState
{
    CGSize pdfSize = CGSizeMake(160, 64);
    [self.mapHouseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-house-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.mapHouseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-house-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.mapHouseButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-house-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
    
    [self.mapRetailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-retail-160x55.pdf" atSize:pdfSize] forState:UIControlStateNormal];
    [self.mapRetailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-retail-highlighted-160x55.pdf" atSize:pdfSize] forState:UIControlStateHighlighted];
    [self.mapRetailButton setBackgroundImage:[UIImage imageWithPDFNamed:@"dining/segment-retail-selected-160x55.pdf" atSize:pdfSize] forState:UIControlStateSelected];
}

#pragma mark - Core Data

- (NSManagedObjectContext *)managedObjectContext {
    return [CoreDataManager managedObjectContext];
    
//    if (_managedObjectContext != nil) {
//        return _managedObjectContext;
//    }
//    
//    _managedObjectContext = [[NSManagedObjectContext alloc] init];
//    _managedObjectContext.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
//    _managedObjectContext.undoManager = nil;
//    _managedObjectContext.stalenessInterval = 0;
//    
//    return _managedObjectContext;
}

- (void)refreshSelectedTypeOfVenues {
    if (self.isShowingHouseDining) {
        [self fetchHouseVenues];
    } else {
        [self fetchRetailVenues];
    }
    if (self.isShowingMap) {
        [self updateMapView];
    } else {
        [self.listView reloadData];
    }
}

- (void)fetchHouseVenues {
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

- (void)fetchRetailVenues {
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.listView reloadData];
}

- (RetailVenue *) retailVenueAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.favoritedRetailVenues count] && indexPath.section == 0) {
        return self.favoritedRetailVenues[indexPath.row];
    } else if ([self.favoritedRetailVenues count]) {
        NSIndexPath *offsetPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
        return [self.fetchedResultsController objectAtIndexPath:offsetPath];            // need to offset the path because fetchedResultsController does not know about favorites
    } else {
        return [self.fetchedResultsController objectAtIndexPath:indexPath];             // no favorites, no need to offset
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.isShowingHouseDining) {
        if ([self.favoritedRetailVenues count] && section == 0) {
            return [self.favoritedRetailVenues count];
        } else if ([self.favoritedRetailVenues count]) {
            return [[self.fetchedResultsController sections][section - 1] numberOfObjects];         // need to offset section when favorites are there
        }
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
    if (self.isShowingHouseDining) {
        return _houseSectionCount;
    } else {
        NSInteger sectionCount = [[self.fetchedResultsController sections] count];
        return ([self.favoritedRetailVenues count]) ? sectionCount + 1 : sectionCount;
    }
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if (self.isShowingHouseDining) {
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
    
    if (self.isShowingHouseDining && indexPath.section != _venuesSectionIndex) {
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
    if (self.isShowingHouseDining && indexPath.section == _announcementSectionIndex) {
        // set announcement background color to yellow color
        cell.backgroundColor = [UIColor colorWithRed:255/255.0 green:253/255.0 blue:205/255.0 alpha:1];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)configureAnnouncementCell:(UITableViewCell *)cell {
    cell.textLabel.text = [[[[DiningData sharedData] announcementsHTML] stringByStrippingTags] stringByDecodingXMLEntities];
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
    
    RetailVenue *venue = [self retailVenueAtIndexPath:indexPath];
    
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
    if (self.isLoading) {
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
        return;
    }
    
    if (!self.isShowingHouseDining) {
        RetailVenue *venue = [self retailVenueAtIndexPath:indexPath];
        
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
        MITSingleWebViewCellTableViewController *vc = [[MITSingleWebViewCellTableViewController alloc] init];
        vc.title = @"Announcements";
        vc.webViewInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        vc.htmlContent = [[DiningData sharedData] announcementsHTML];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isShowingHouseDining) {
        RetailVenue *venue = [self retailVenueAtIndexPath:indexPath];
        return [DiningLocationCell heightForRowWithTitle:venue.name subtitle:[venue hoursToday]];
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
    UIColor *bc = [UIColor colorWithHexString:@"#a41f35"];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.listView.bounds), 25)];
    view.backgroundColor = bc;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, CGRectGetWidth(view.bounds) - 10 , 25)];
    label.backgroundColor = bc;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.text = [self titleForHeaderInSection:section];
    
    if ([self.favoritedRetailVenues count] && section == 0) {
        UIImageView *favIcon = [[UIImageView alloc] initWithFrame:CGRectMake(9, 2, 18, 18)];
        favIcon.image = [UIImage imageNamed:@"dining/bookmark_selected"];
        label.frame = CGRectMake(CGRectGetMaxX(favIcon.frame) + 3, 0, CGRectGetWidth(view.bounds) - (CGRectGetMaxX(favIcon.frame) + 10), 25);  // shift label to the right
        [view addSubview:favIcon];
    }
    
    [view addSubview:label];
    
    return view;
}

- (NSString *) titleForHeaderInSection:(NSInteger)section // not the UITableViewDataSource method.
{
    if (!self.isShowingHouseDining) {
        // showing Retail Dining data
        if ([self.favoritedRetailVenues count] && section == 0) {
            return @"Favorites";
        }
        RetailVenue *venue = [self retailVenueAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        NSString *building = venue.building;
        // This may need to have an `updated` block in case locations aren't actually loaded yet.
        NSArray *matches = [[FacilitiesLocationData sharedData] locationsWithNumber:building updated:nil];
        if ([matches count] > 0) {
            building = [building stringByAppendingFormat:@" - %@", ((FacilitiesLocation *)matches[0]).name];
        }
        return building;
    } else {
        // showing House Dining data
        NSString *announcement = [[DiningData sharedData] announcementsHTML];
        if ([announcement length] && section == 0) {
            return nil;
        } else if((![announcement length] && section == 0) || (announcement && section == 1)) {
            return @"Venues";
        } else if ((![announcement length] && section == 1)|| (announcement && section == 2)) {
            return @"Resources";
        }
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.isShowingHouseDining && [[DiningData sharedData] announcementsHTML] && section == 0) {
        return 0;
    }
    
    return 25;
}

#pragma mark - MapView Methods

- (void)updateMapView {
    NSArray *venues = [self.fetchedResultsController fetchedObjects];
    [self updateMapWithDiningPlaces:venues];
}

- (void)setupMapBoundingBoxAnimated:(BOOL)animated
{
    [self.view layoutIfNeeded]; // ensure that map has autoresized before setting region
    
    if ([self.places count] > 0) {
        MKMapRect zoomRect = MKMapRectNull;
        for (id <MKAnnotation> annotation in self.places)
        {
            MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
            MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        double inset = -zoomRect.size.width * 0.1;
        [self.mapView setVisibleMapRect:MKMapRectInset(zoomRect, inset, inset) animated:YES];
    } else {
        [self.mapView setRegion:kMITShuttleDefaultMapRegion animated:animated];
    }
}

#pragma mark - Places

- (void)setPlaces:(NSArray *)places
{
    [self setPlaces:places animated:NO];
}

- (void)setPlaces:(NSArray *)places animated:(BOOL)animated
{
    _places = places;
    [self refreshPlaceAnnotations];
    [self setupMapBoundingBoxAnimated:animated];
}

- (void)clearPlacesAnimated:(BOOL)animated
{
    [self setPlaces:nil animated:animated];
}

- (void)refreshPlaceAnnotations
{
    [self removeAllPlaceAnnotations];
    [self.mapView addAnnotations:self.places];
}

- (void)removeAllPlaceAnnotations
{
    NSMutableArray *annotationsToRemove = [NSMutableArray array];
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MITDiningPlace class]]) {
            [annotationsToRemove addObject:annotation];
        }
    }
    [self.mapView removeAnnotations:annotationsToRemove];
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MITDiningPlace class]]) {
        MITMapPlaceAnnotationView *annotationView = (MITMapPlaceAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        if (!annotationView) {
            annotationView = [[MITMapPlaceAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kMITMapPlaceAnnotationViewIdentifier];
        }
        [annotationView setNumber:[(MITDiningPlace *)annotation displayNumber]];
        
        return annotationView;
    }
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(calloutTapped:)];
    [view addGestureRecognizer:tap];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
        [view removeGestureRecognizer:gestureRecognizer];
    }
}

- (void)calloutTapped:(UITapGestureRecognizer *)tap
{
    [self showDetailForAnnotationView:(MKAnnotationView *)tap.view];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self showDetailForAnnotationView:view];
}

- (void)showDetailForAnnotationView:(MKAnnotationView *)view
{
    if ([view isKindOfClass:[MITMapPlaceAnnotationView class]]) {
        MITDiningPlace *place = view.annotation;
        if (place.houseVenue) {
            DiningHallMenuViewController *detailVC = [[DiningHallMenuViewController alloc] init];
            detailVC.venue = place.houseVenue;
            [self.navigationController pushViewController:detailVC animated:YES];
        } else if (place.retailVenue) {
            DiningRetailInfoViewController *detailVC = [[DiningRetailInfoViewController alloc] init];
            detailVC.venue = place.retailVenue;
            [self.navigationController pushViewController:detailVC animated:YES];
        }
        
    }
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (self.shouldRefreshAnnotationsOnNextMapRegionChange) {
        [self refreshPlaceAnnotations];
        self.shouldRefreshAnnotationsOnNextMapRegionChange = NO;
    }
    
}

#pragma mark - Loading Events Into Map

- (void)updateMapWithDiningPlaces:(NSArray *)diningPlaceArray
{
    [self removeAllPlaceAnnotations];
    NSMutableArray *annotationsToAdd = [NSMutableArray array];
    int totalNumberOfPlacesWithoutLocation = 0;
    for (int i = 0; i < diningPlaceArray.count; i++) {
    
        id venue = diningPlaceArray[i];
        MITDiningPlace *diningPlace = nil;
        if ([venue isKindOfClass:[RetailVenue class]]) {
            diningPlace = [[MITDiningPlace alloc] initWithRetailVenue:venue];
        } else if ([venue isKindOfClass:[HouseVenue class]]) {
            diningPlace = [[MITDiningPlace alloc] initWithHouseVenue:venue];
        }
        if (diningPlace) {
            diningPlace.displayNumber = (i + 1) - totalNumberOfPlacesWithoutLocation;
            [annotationsToAdd addObject:diningPlace];
        } else {
            totalNumberOfPlacesWithoutLocation++;
        }
    }
    
    self.places = annotationsToAdd;
}

#pragma mark - MapView Getter

- (MKMapView *)mapView
{
    return self.tiledMapView.mapView;
}

@end
