#import "MITMapIndexedCategoryViewController.h"
#import "MITMapModelController.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITMapPlace+Comparison.h"
#import "MITMapPlaceCell.h"

static NSString * const kMITMapIndexedPlaceCellIdentifier = @"MITMapIndexedPlaceCell";

static const CGFloat kEstimatedSectionIndexWidth = 30.0; // Can't access section index view, so we have to estimate

NSInteger MITMapSectionIndexSeparatorDotCountForOrientation(UIInterfaceOrientation orientation)
{
    return UIInterfaceOrientationIsLandscape(orientation) ? 1 : 3;
}

@interface MITMapIndexedCategoryViewController ()

@property (nonatomic, strong) NSMutableArray *indexedPlaces;
@property (nonatomic, copy) NSArray *sectionIndexTitles;

@end

@implementation MITMapIndexedCategoryViewController

@synthesize delegate = _delegate;

#pragma mark - Init

- (instancetype)initWithCategory:(MITMapCategory *)category
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _category = category;
        [self refreshPlaces];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = self.category.name;
    [self setupTableView];
    [self setupDoneBarButtonItem];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self resetSectionIndexTitles];
    
    // Reload cell heights
    [self.tableView reloadData];
}

#pragma mark - Setup

- (void)setupTableView
{
    UINib *numberedResultCellNib = [UINib nibWithNibName:NSStringFromClass([MITMapPlaceCell class]) bundle:nil];
    [self.tableView registerNib:numberedResultCellNib forCellReuseIdentifier:kMITMapIndexedPlaceCellIdentifier];
}

- (void)setupDoneBarButtonItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
}

#pragma mark - Button Actions

- (void)doneButtonItemTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Places

- (void)refreshPlaces
{
    [self showRefreshControlLoadingAnimation];
    
    MITMapModelController *mapModelController = [MITMapModelController sharedController];
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    [self.category.children enumerateObjectsUsingBlock:^(MITMapCategory *childCategory, NSUInteger idx, BOOL *stop) {
        [mapModelController placesInCategory:childCategory loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
            NSError *fetchError = nil;
            NSArray *unsortedSection = [mainQueueContext executeFetchRequest:fetchRequest error:&fetchError];
            if (self.shouldSortCategory){
                self.indexedPlaces[idx] =  unsortedSection = [unsortedSection sortedArrayUsingSelector:@selector(compare:)];
            }
            else {
                self.indexedPlaces[idx] = unsortedSection;
            }
            [self.tableView reloadData];
            if ([self isCategoryLoadingComplete]) {
                [self hideRefreshControlLoadingAnimation];
            }
        }];
    }];
}

// Use UIRefreshControl to indicate loading, then remove it when network calls complete

- (void)showRefreshControlLoadingAnimation
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl beginRefreshing];
}

- (void)hideRefreshControlLoadingAnimation
{
    [self.refreshControl endRefreshing];
    self.refreshControl = nil;
}

#pragma mark - UITableViewDataSource Helpers

- (NSMutableArray *)indexedPlaces
{
    if (!_indexedPlaces) {
        NSInteger childCategoryCount = [self.category.children count];
        NSMutableArray *indexedPlaces = [NSMutableArray arrayWithCapacity:childCategoryCount];
        for (NSInteger i = 0; i < childCategoryCount; ++i) {
            [indexedPlaces addObject:[NSNull null]];
        }
        _indexedPlaces = indexedPlaces;
    }
    return _indexedPlaces;
}

- (MITMapPlace *)placeForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *places = self.indexedPlaces[indexPath.section];
    return places[indexPath.row];
}

- (NSArray *)sectionIndexTitles
{
    if (!_sectionIndexTitles) {
        NSMutableArray *sectionIndexTitles = [NSMutableArray array];
        [self.category.children enumerateObjectsUsingBlock:^(MITMapCategory *childCategory, NSUInteger idx, BOOL *stop) {
            [sectionIndexTitles addObject:[childCategory sectionIndexTitle]];
            if (idx < [self.category.children count] - 1) {
                // Add dot separators between actual section index titles
                for (NSInteger dotIndex = 0; dotIndex < MITMapSectionIndexSeparatorDotCountForOrientation([[UIApplication sharedApplication] statusBarOrientation]); ++dotIndex) {
                    [sectionIndexTitles addObject:@"\u2022"];
                }
            }
        }];
        _sectionIndexTitles = [NSArray arrayWithArray:sectionIndexTitles];
    }
    return _sectionIndexTitles;
}

- (void)resetSectionIndexTitles
{
    self.sectionIndexTitles = nil;
    [self.tableView reloadData];
}

- (BOOL)isCategoryLoadingComplete
{
    for (id places in self.indexedPlaces) {
        if (places == [NSNull null]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self isCategoryLoadingComplete]) {
        return [self.indexedPlaces count];
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id places = self.indexedPlaces[section];
    if ([places isKindOfClass:[NSArray class]]) {
        return [places count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapIndexedPlaceCellIdentifier forIndexPath:indexPath];
    [cell setPlace:[self placeForIndexPath:indexPath]];
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if ([self isCategoryLoadingComplete]) {
        return self.sectionIndexTitles;
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSInteger effectiveIndex = index + 1;   // Touching the dot after the index title should select that section
    float indexTitlesPerSection = (float)(MITMapSectionIndexSeparatorDotCountForOrientation([[UIApplication sharedApplication] statusBarOrientation]) + 1);    // Number of index titles that map to a single section
    return floor(effectiveIndex / indexTitlesPerSection);
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kMapPlaceCellEstimatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [MITMapPlaceCell heightForPlace:[self placeForIndexPath:indexPath] tableViewWidth:(self.tableView.frame.size.width - kEstimatedSectionIndexWidth) accessoryType:UITableViewCellAccessoryNone];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MITMapCategory *childCategory = self.category.children[section];
    return childCategory.name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapPlace *place = [self placeForIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(placeSelectionViewController:didSelectPlace:)]) {
        [self.delegate placeSelectionViewController:self didSelectPlace:place];
    }
}

@end
