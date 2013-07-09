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
#import "UIScrollView+SVPullToRefresh.h"

@interface DiningMapListViewController() <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, MGSMapViewDelegate, MGSLayerDelegate>

@property (nonatomic, strong) IBOutlet UITableView * listView;
@property (nonatomic, strong) IBOutlet UIView * listTabContainerView;
@property (nonatomic, strong) IBOutlet UIButton * listHouseButton;
@property (nonatomic, strong) IBOutlet UIButton * listRetailButton;
@property (nonatomic, strong) IBOutlet UIView * mapSegmentContainerView;
@property (nonatomic, strong) IBOutlet UIButton * mapHouseButton;
@property (nonatomic, strong) IBOutlet UIButton * mapRetailButton;
@property (nonatomic, strong) IBOutlet UIView *mapContainer;
@property (nonatomic, strong) MGSMapView *mapView;
@property (nonatomic, assign) BOOL isAnimating;
@property (nonatomic, assign) BOOL isShowingMap;
@property (nonatomic, assign) BOOL isShowingHouseDining;
@property (nonatomic, assign, getter = isLoading) BOOL loading;

@property (nonatomic, assign) NSInteger announcementSectionIndex;
@property (nonatomic, assign) NSInteger venuesSectionIndex;
@property (nonatomic, assign) NSInteger resourcesSectionIndex;
@property (nonatomic, assign) NSInteger houseSectionCount;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSArray *favoritedRetailVenues;

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

    self.view.backgroundColor = [UIColor colorWithHexString:@"#c8cacf"];
    
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
        NSDate *startDate = [NSDate date];
        [[DiningData sharedData] reloadAndCompleteWithBlock:^{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf refreshSelectedTypeOfVenues];
                [weakSelf updatePullToRefreshSubtitle];
                [weakSelf.listView.pullToRefreshView stopAnimating];
                NSLog(@"Time taken: %f", [[NSDate date] timeIntervalSinceDate:startDate]);
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

- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *selectedIndexPath = [self.listView indexPathForSelectedRow];
    [self.listView deselectRowAtIndexPath:selectedIndexPath animated:animated];
    self.favoritedRetailVenues = [CoreDataManager objectsForEntity:@"RetailVenue" matchingPredicate:[NSPredicate predicateWithFormat:@"favorite == YES"] sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    [self.listView reloadData];
}

- (void)showHouse:(id)sender {
    if (!self.isShowingHouseDining) {
        self.isShowingHouseDining = YES;
        [self tabBarDidChange:sender];
    }
}

- (void)showRetail:(id)sender {
    if (self.isShowingHouseDining) {
        self.isShowingHouseDining = NO;
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
    if (!self.isShowingMap && self.mapView) {
        [self.mapView removeFromSuperview];
        self.mapView = nil;
    }
}

- (void) toggleMapList:(id)sender
{
    if (!self.isAnimating) {
        self.navigationItem.rightBarButtonItem.title = (self.isShowingMap)? @"Map" : @"List";
        
        if (self.isShowingMap) {
            [self.listView reloadData];
            // animate to the list
            [UIView animateWithDuration:0.4f animations:^{
                [self layoutListState];
                self.isAnimating = YES;
            } completion:^(BOOL finished) {
                self.isAnimating = NO;
            }];
            
        } else {
            if (!self.mapView) {
                self.mapView = [[MGSMapView alloc] initWithFrame:self.mapContainer.bounds];
                self.mapView.delegate = self;
                [self.mapContainer addSubview:self.mapView];
            }
            [self annotateVenues];
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
    CGRect frame = self.listTabContainerView.frame;
    frame.origin = CGPointMake(0.0, 0.0);
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
    if ([self isShowingMap]) {
        [self annotateVenues];
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
    if (![self showingHouseDining]) {
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
    if ([self showingHouseDining]) {
        return _houseSectionCount;
    } else {
        NSInteger sectionCount = [[self.fetchedResultsController sections] count];
        return ([self.favoritedRetailVenues count]) ? sectionCount + 1 : sectionCount;
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
    if (![self showingHouseDining]) {
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
        MITSingleWebViewCellTableViewController *vc = [[MITSingleWebViewCellTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.title = @"Announcements";
        vc.webViewInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        vc.htmlContent = [[DiningData sharedData] announcementsHTML];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self showingHouseDining]) {
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
    if (![self showingHouseDining]) {
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
