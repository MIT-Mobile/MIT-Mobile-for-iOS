#import "MITDiningHouseHomeViewControllerPad.h"
#import "MITDiningHallMealCollectionCell.h"
#import "MITCoreData.h"
#import "MITAdditions.h"
#import "MITDiningHallMealCollectionHeader.h"
#import "MITDiningHouseVenue.h"
#import "MITDiningHouseDay.h"
#import "MITDiningMeal.h"
#import "TopAlignedCollectionViewFlowLayout.h"
#import "MITDiningHouseMealSelectorPad.h"
#import "UIImage+PDF.h"
#import "MITDiningMenuItem.h"


static NSString * const kMITDiningHallMealCollectionCellNib = @"MITDiningHallMealCollectionCell";
static NSString * const kMITDiningHallMealCollectionCellIdentifier = @"kMITDiningHallMealCollectionCellIdentifier";

static NSString * const kMITDiningHallMealCollectionHeaderNib = @"MITDiningHallMealCollectionHeader";
static NSString * const kMITDiningHallMealCollectionHeaderIdentifier = @"kMITDiningHallMealCollectionHeaderIdentifier";

static CGFloat const kMITDiningHallCollectionViewSectionHorizontalPadding = 60.0;

@interface MITDiningHouseHomeViewControllerPad () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate, MITDiningHouseMealSelectorPadDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet MITDiningHouseMealSelectorPad *mealSelector;
@property (nonatomic, strong) NSDate *currentlySelectedDate;
@property (nonatomic, strong) NSString *currentlySelectedMeal;
@property (nonatomic, strong) NSArray *menuItemsBySection;
@property (nonatomic, strong) NSArray *dietaryFlagFilters;
@property (nonatomic, strong) NSArray *filteredMenuItemsBySection;


@end

@implementation MITDiningHouseHomeViewControllerPad

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
    
    self.mealSelector.horizontalInset = kMITDiningHallCollectionViewSectionHorizontalPadding / 2;
    self.mealSelector.delegate = self;
    
    self.collectionView.collectionViewLayout = [[TopAlignedCollectionViewFlowLayout alloc] init];
    [self.collectionView registerNib:[UINib nibWithNibName:kMITDiningHallMealCollectionCellNib bundle:nil] forCellWithReuseIdentifier:kMITDiningHallMealCollectionCellIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:kMITDiningHallMealCollectionHeaderNib bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kMITDiningHallMealCollectionHeaderIdentifier];
    [self.collectionView setContentInset:UIEdgeInsetsMake(14, 0, 0, 0)];
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

- (void)setDiningHouses:(NSArray *)diningHouses
{
    if ([_diningHouses isEqualToArray:diningHouses]) {
        return;
    }
    
    _diningHouses = diningHouses;
    
    [self.mealSelector setVenues:self.diningHouses];
    
    [self selectBestMealForCurrentDate];
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
