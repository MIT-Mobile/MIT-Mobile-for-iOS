#import "MITDiningHomeViewControllerPad.h"
#import "MITDiningHallMealCollectionCell.h"
#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITDiningWebservices.h"
#import "MITDiningHallMealCollectionHeader.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "TopAlignedCollectionViewFlowLayout.h"
#import "MITDiningHouseMealSelectorPad.h"
#import "UIImage+PDF.h"
#import "MITDiningMenuItem.h"
#import "MITSingleWebViewCellTableViewController.h"
#import "MITDiningVenues.h"
#import "MITDiningLinksTableViewController.h"

static NSString * const kMITDiningHallMealCollectionCellNib = @"MITDiningHallMealCollectionCell";
static NSString * const kMITDiningHallMealCollectionCellIdentifier = @"kMITDiningHallMealCollectionCellIdentifier";

static NSString * const kMITDiningHallMealCollectionHeaderNib = @"MITDiningHallMealCollectionHeader";
static NSString * const kMITDiningHallMealCollectionHeaderIdentifier = @"kMITDiningHallMealCollectionHeaderIdentifier";

static CGFloat const kMITDiningHallCollectionViewSectionHorizontalPadding = 60.0;

@interface MITDiningHomeViewControllerPad () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, MITDiningHouseMealSelectorPadDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) MITDiningDining *diningData;
@property (nonatomic, strong) NSArray *diningHouses;

@property (nonatomic, weak) IBOutlet MITDiningHouseMealSelectorPad *mealSelector;
@property (nonatomic, strong) NSDate *currentlySelectedDate;
@property (nonatomic, strong) NSString *currentlySelectedMeal;
@property (nonatomic, strong) NSArray *menuItemsBySection;
@property (nonatomic, strong) NSArray *dietaryFlagFilters;
@property (nonatomic, strong) NSArray *filteredMenuItemsBySection;
@property (nonatomic, strong) UISegmentedControl *diningVenueTypeControl;
@property (nonatomic, strong) UIPopoverController *announcementsPopoverController;
@property (nonatomic, strong) UIPopoverController *linksPopoverController;
@property (nonatomic, strong) UIBarButtonItem *announcementsBarButton;
@property (nonatomic, strong) UIBarButtonItem *linksBarButton;

@end

@implementation MITDiningHomeViewControllerPad

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
    
    [self setupNavBar];
    [self setupToolbar];
    
    self.mealSelector.horizontalInset = kMITDiningHallCollectionViewSectionHorizontalPadding / 2;
    self.mealSelector.delegate = self;
    
    self.collectionView.collectionViewLayout = [[TopAlignedCollectionViewFlowLayout alloc] init];
    [self.collectionView registerNib:[UINib nibWithNibName:kMITDiningHallMealCollectionCellNib bundle:nil] forCellWithReuseIdentifier:kMITDiningHallMealCollectionCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:kMITDiningHallMealCollectionHeaderNib bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kMITDiningHallMealCollectionHeaderIdentifier];
    [self.collectionView setContentInset:UIEdgeInsetsMake(14, 0, 0, 0)];
    
    [self setupFetchedResultsController];
    [MITDiningWebservices getDiningWithCompletion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.collectionView reloadData];
}

- (void)setupNavBar
{
    self.navigationController.navigationBar.translucent = NO;

    [self.navigationController.navigationBar setShadowImage:[UIImage imageNamed:@"global/TransparentPixel"]];
    NSLog(@"navbar bg: %@", self.navigationController.navigationBar.backgroundColor);
    NSLog(@"mit bg: %@", [UIColor mit_backgroundColor]);
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.navigationController.navigationBar setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    
    self.diningVenueTypeControl = [[UISegmentedControl alloc] initWithItems:@[@"Dining Halls", @"Other"]];
    [self.diningVenueTypeControl setSelectedSegmentIndex:0];
    self.navigationItem.titleView = self.diningVenueTypeControl;
}

- (void)setupToolbar
{
    self.announcementsBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Announcements" style:UIBarButtonItemStylePlain target:self action:@selector(announcementsButtonPressed:)];
    self.linksBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Links" style:UIBarButtonItemStylePlain target:self action:@selector(linksButtonPressed:)];
    UIBarButtonItem *filtersButton = [[UIBarButtonItem alloc] initWithTitle:@"Filters" style:UIBarButtonItemStylePlain target:self action:@selector(filtersButtonPressed:)];
    
    CGSize announcementsSize = [self.announcementsBarButton.title sizeWithAttributes:[self.announcementsBarButton titleTextAttributesForState:UIControlStateNormal]];
    CGSize filtersSize = [filtersButton.title sizeWithAttributes:[self.announcementsBarButton titleTextAttributesForState:UIControlStateNormal]];
    
    UIBarButtonItem *evenPaddingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    evenPaddingButton.width = announcementsSize.width - filtersSize.width;
    
    self.toolbarItems = @[self.announcementsBarButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.linksBarButton,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          evenPaddingButton,
                          filtersButton];
}

- (void)selectDate:(NSDate *)date mealName:(NSString *)mealName
{
    self.currentlySelectedDate = date;
    self.currentlySelectedMeal = mealName;
    
    [self refreshViews];
}

- (void)refreshViews
{
    [self recreateMenuItemsBySection];
    [self.collectionView reloadData];
}

- (void)recreateMenuItemsBySection
{
    NSMutableArray *newMenuItemsBySection = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.diningHouses.count; i++) {
        NSMutableArray *currentSectionMenuItemsArray = [NSMutableArray array];
        MITDiningHouseVenue *venue = self.diningHouses[i];
        
        for (MITDiningHouseDay *diningDay in venue.mealsByDay) {
            if ([diningDay.date isEqualToDate:self.currentlySelectedDate]) {
                for (MITDiningMeal *meal in diningDay.meals) {
                    if ([meal.name isEqualToString:self.currentlySelectedMeal]) {
                        for (MITDiningMenuItem *menuItem in meal.items) {
                            [currentSectionMenuItemsArray addObject:menuItem];
                        }
                    }
                }
            }
        }
        
        newMenuItemsBySection[i] = currentSectionMenuItemsArray;
    }
    
    self.menuItemsBySection = [NSArray arrayWithArray:newMenuItemsBySection];
    [self refreshFilteredMenuItems];
}

- (void)selectBestMealForCurrentDate
{
    MITDiningHouseDay *dayToSelect = nil;
    
    for (MITDiningHouseVenue *venue in self.diningHouses) {
        for (MITDiningHouseDay *day in venue.mealsByDay) {
            if ([[day.date dateWithoutTime] isEqualToDate:[[NSDate date] dateWithoutTime]]) {
                dayToSelect = day;
                break;
            }
        }
    }
    
    if (!dayToSelect && self.diningHouses.count > 0) {
        MITDiningHouseVenue *venue = self.diningHouses[0];
        if (venue.mealsByDay.count > 0) {
            dayToSelect = venue.mealsByDay[0];
        }
    }
    
    if (dayToSelect) {
        NSDate *currentDate = [NSDate date];
        MITDiningMeal *mealToSelect = [dayToSelect bestMealForDate:currentDate];
        [self.mealSelector selectMeal:mealToSelect.name onDate:currentDate];
        [self selectDate:dayToSelect.date mealName:mealToSelect.name];
    }
}

- (void)setDietaryFlagFilters:(NSArray *)filters
{
    if ([_dietaryFlagFilters isEqualToArray:filters]) {
        return;
    }
    
    _dietaryFlagFilters = filters;
    [self refreshFilteredMenuItems];
    [self.collectionView reloadData];
}

- (void)refreshFilteredMenuItems
{
    NSMutableArray *newFilteredMenuItems = [NSMutableArray array];
    
    for (NSArray *menuItemsArray in self.menuItemsBySection) {
        NSMutableArray *filteredMenuItemsArray = [NSMutableArray array];
        
        for (MITDiningMenuItem *menuItem in menuItemsArray) {
            if (menuItem.dietaryFlags && [menuItem.dietaryFlags isKindOfClass:[NSArray class]]) {
                for (NSString *dietaryFlag in menuItem.dietaryFlags) {
                    for (NSString *dietaryFlagFilter in self.dietaryFlagFilters) {
                        if ([dietaryFlag isEqualToString:dietaryFlagFilter]) {
                            [filteredMenuItemsArray addObject:menuItem];
                        }
                    }
                }
            }
        }
        
        [newFilteredMenuItems addObject:filteredMenuItemsArray];
    }
    
    self.filteredMenuItemsBySection = [NSArray arrayWithArray:newFilteredMenuItems];
}

#pragma mark - Toolbar Button Actions

- (void)announcementsButtonPressed:(id)sender
{
    MITSingleWebViewCellTableViewController *vc = [[MITSingleWebViewCellTableViewController alloc] init];
    vc.title = @"Announcements";
    vc.webViewInsets = UIEdgeInsetsMake(10, 0, 10, 10);
    vc.htmlContent = self.diningData.announcementsHTML;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.announcementsPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.announcementsPopoverController presentPopoverFromBarButtonItem:self.announcementsBarButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)linksButtonPressed:(id)sender
{
    MITDiningLinksTableViewController *vc = [[MITDiningLinksTableViewController alloc] init];
    vc.diningLinks = [self.diningData.links array];
    vc.title = @"Links";
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    self.linksPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
    [self.linksPopoverController presentPopoverFromBarButtonItem:self.linksBarButton permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
}

- (void)filtersButtonPressed:(id)sender
{
    // TODO: Show announcements popover
}

#pragma mark - Fetched Results Controller

- (void)setupFetchedResultsController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MITDiningDining"
                                              inManagedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"url"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]
                                          sectionNameKeyPath:nil
                                                   cacheName:nil];
    self.fetchedResultsController = fetchedResultsController;
    _fetchedResultsController.delegate = self;
    
    [self.fetchedResultsController performFetch:nil];
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        self.diningData = self.fetchedResultsController.fetchedObjects[0];
        self.diningHouses = [self.diningData.venues.house array];
    }
    
    [self.mealSelector setVenues:self.diningHouses];
    
    [self selectBestMealForCurrentDate];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.fetchedResultsController.fetchedObjects.count > 0) {
        self.diningData = self.fetchedResultsController.fetchedObjects[0];
        self.diningHouses = [self.diningData.venues.house array];
    }
    
    [self.mealSelector setVenues:self.diningHouses];
    
    if (!self.currentlySelectedMeal) {
        [self selectBestMealForCurrentDate];
    } else {
        [self refreshViews];
    }
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.diningHouses.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.dietaryFlagFilters.count > 0) {
        NSArray *menuItemsArray = self.filteredMenuItemsBySection[section];
        return menuItemsArray.count;
    } else {
        NSArray *menuItemsArray = self.menuItemsBySection[section];
        return menuItemsArray.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningHallMealCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMITDiningHallMealCollectionCellIdentifier forIndexPath:indexPath];
    
    NSArray *menuItemsArray;
    if (self.dietaryFlagFilters.count > 0) {
        menuItemsArray = self.filteredMenuItemsBySection[indexPath.section];
    } else {
        menuItemsArray = self.menuItemsBySection[indexPath.section];
    }
    MITDiningMenuItem *menuItem = menuItemsArray[indexPath.item];
    
    [cell setMenuItem:menuItem];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    MITDiningHallMealCollectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kMITDiningHallMealCollectionHeaderIdentifier forIndexPath:indexPath];
    
    MITDiningHouseVenue *venue = self.diningHouses[indexPath.section];
    MITDiningHouseDay *day;
    for (MITDiningHouseDay *diningDay in venue.mealsByDay) {
        if ([diningDay.date isEqualToDate:self.currentlySelectedDate]) {
            day = diningDay;
        }
    }
    
    [header setDiningHouseVenue:venue day:day mealName:self.currentlySelectedMeal];
    
    return header;
}

#pragma mark - UICollectionViewDelegate Methods

#pragma mark - UICollectionViewDelegateFlowLayout Methods

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat interItemSpacing = ((UICollectionViewFlowLayout *)collectionView.collectionViewLayout).minimumInteritemSpacing;
    CGFloat cellWidth = 0;
    NSInteger numberOfColumns = 0;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        numberOfColumns = 3;
    } else {
        numberOfColumns = 4;
    }
    
    cellWidth = (collectionView.bounds.size.width - (2 * kMITDiningHallCollectionViewSectionHorizontalPadding) - ((numberOfColumns - 1) * interItemSpacing)) / numberOfColumns;
    
    NSArray *menuItemsArray;
    if (self.dietaryFlagFilters.count > 0) {
        menuItemsArray = self.filteredMenuItemsBySection[indexPath.section];
    } else {
        menuItemsArray = self.menuItemsBySection[indexPath.section];
    }
    
    MITDiningMenuItem *menuItem = menuItemsArray[indexPath.item];
    CGFloat cellHeight = [MITDiningHallMealCollectionCell heightForMenuItem:menuItem width:cellWidth];
    
    return CGSizeMake(cellWidth, cellHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    MITDiningHouseVenue *venue = self.diningHouses[section];
    MITDiningHouseDay *day;
    for (MITDiningHouseDay *diningDay in venue.mealsByDay) {
        if ([diningDay.date isEqualToDate:self.currentlySelectedDate]) {
            day = diningDay;
        }
    }
    
    CGFloat headerHeight = [MITDiningHallMealCollectionHeader heightForDiningHouseVenue:venue day:day mealName:self.currentlySelectedMeal collectionViewWidth:collectionView.bounds.size.width];
    return CGSizeMake(collectionView.bounds.size.width, headerHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, kMITDiningHallCollectionViewSectionHorizontalPadding, 10, kMITDiningHallCollectionViewSectionHorizontalPadding);
}

#pragma mark - MITDiningHouseMealSelectorPadDelegate Methods

- (void)diningHouseMealSelector:(MITDiningHouseMealSelectorPad *)mealSelector didSelectMeal:(NSString *)meal onDate:(NSDate *)date
{
    [self selectDate:date mealName:meal];
}

@end
