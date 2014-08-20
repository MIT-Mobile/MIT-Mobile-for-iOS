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

static NSString * const kMITDiningHallMealCollectionCellNib = @"MITDiningHallMealCollectionCell";
static NSString * const kMITDiningHallMealCollectionCellIdentifier = @"kMITDiningHallMealCollectionCellIdentifier";

static NSString * const kMITDiningHallMealCollectionHeaderNib = @"MITDiningHallMealCollectionHeader";
static NSString * const kMITDiningHallMealCollectionHeaderIdentifier = @"kMITDiningHallMealCollectionHeaderIdentifier";

static CGFloat const kMITDiningHallCollectionViewSectionHorizontalPadding = 60.0;

@interface MITDiningHomeViewControllerPad () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) NSDate *currentlySelectedDate;
@property (nonatomic, strong) NSString *currentlySelectedMeal;
@property (nonatomic, strong) NSArray *menuItemsBySection;

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
    // Do any additional setup after loading the view from its nib.
    
    self.collectionView.collectionViewLayout = [[TopAlignedCollectionViewFlowLayout alloc] init];
    [self.collectionView registerNib:[UINib nibWithNibName:kMITDiningHallMealCollectionCellNib bundle:nil] forCellWithReuseIdentifier:kMITDiningHallMealCollectionCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:kMITDiningHallMealCollectionHeaderNib bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kMITDiningHallMealCollectionHeaderIdentifier];
    
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

- (void)selectDate:(NSDate *)date mealName:(NSString *)mealName
{
    self.currentlySelectedDate = date;
    self.currentlySelectedMeal = mealName;
    
    NSMutableArray *newMenuItemsBySection = [NSMutableArray array];
    
    for (NSInteger i = 0; i < self.fetchedResultsController.fetchedObjects.count; i++) {
        NSMutableArray *currentSectionMenuItemsArray = [NSMutableArray array];
        MITDiningHouseVenue *venue = self.fetchedResultsController.fetchedObjects[i];
        
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
    
    [self.collectionView reloadData];
}

#pragma mark - Fetched Results Controller

- (void)setupFetchedResultsController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MITDiningHouseVenue"
                                              inManagedObjectContext:[[MITCoreDataController defaultController] mainQueueContext]];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"shortName"
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
    
    MITDiningHouseVenue *venue = self.fetchedResultsController.fetchedObjects[0];
    MITDiningHouseDay *day = venue.mealsByDay[0];
    MITDiningMeal *meal = day.meals[0];
    
    [self selectDate:day.date mealName:meal.name];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"context changed");
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.fetchedObjects.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *menuItemsArray = self.menuItemsBySection[section];
    return menuItemsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MITDiningHallMealCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kMITDiningHallMealCollectionCellIdentifier forIndexPath:indexPath];
    
    NSArray *menuItemsArray = self.menuItemsBySection[indexPath.section];
    MITDiningMenuItem *menuItem = menuItemsArray[indexPath.item];
    
    [cell setMenuItem:menuItem];
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    MITDiningHallMealCollectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kMITDiningHallMealCollectionHeaderIdentifier forIndexPath:indexPath];
    
    MITDiningHouseVenue *venue = self.fetchedResultsController.fetchedObjects[indexPath.section];
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
    
    NSArray *menuItemsArray = self.menuItemsBySection[indexPath.section];
    MITDiningMenuItem *menuItem = menuItemsArray[indexPath.item];
    CGFloat cellHeight = [MITDiningHallMealCollectionCell heightForMenuItem:menuItem width:cellWidth];
    
    return CGSizeMake(cellWidth, cellHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    MITDiningHouseVenue *venue = self.fetchedResultsController.fetchedObjects[section];
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

@end
