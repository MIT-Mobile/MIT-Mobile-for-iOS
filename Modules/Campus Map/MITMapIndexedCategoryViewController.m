#import "MITMapIndexedCategoryViewController.h"
#import "MITMapModelController.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"

static NSString * const kMITMapIndexedPlaceCellIdentifier = @"MITMapIndexedPlaceCell";

NSInteger MITMapSectionIndexSeparatorDotCountForOrientation(UIInterfaceOrientation orientation)
{
    return UIInterfaceOrientationIsLandscape(orientation) ? 1 : 3;
}

@interface MITMapIndexedCategoryViewController ()

@property (nonatomic, strong) NSMutableArray *indexedPlaces;
@property (nonatomic, copy) NSArray *sectionIndexTitles;

@end

@implementation MITMapIndexedCategoryViewController

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
    self.sectionIndexTitles = nil;
    [self.tableView reloadData];
}

#pragma mark - Setup

- (void)setupDoneBarButtonItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonItemTapped:)];
}

#pragma mark - Button Actions

- (void)doneButtonItemTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (NSArray *)sectionIndexTitles
{
    if (!_sectionIndexTitles) {
        NSMutableArray *sectionIndexTitles = [NSMutableArray array];
        [self.category.children enumerateObjectsUsingBlock:^(MITMapCategory *childCategory, NSUInteger idx, BOOL *stop) {
            [sectionIndexTitles addObject:[childCategory sectionIndexTitle]];
            if (idx < [self.category.children count] - 1) {
                for (NSInteger dotIndex = 0; dotIndex < MITMapSectionIndexSeparatorDotCountForOrientation(self.interfaceOrientation); ++dotIndex) {
                    [sectionIndexTitles addObject:@"\u2022"];
                }
            }
        }];
        _sectionIndexTitles = [NSArray arrayWithArray:sectionIndexTitles];
    }
    return _sectionIndexTitles;
}

- (void)refreshPlaces
{
    MITMapModelController *mapModelController = [MITMapModelController sharedController];
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
    [self.category.children enumerateObjectsUsingBlock:^(MITMapCategory *childCategory, NSUInteger idx, BOOL *stop) {
        [mapModelController placesInCategory:childCategory loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
            NSError *fetchError = nil;
            self.indexedPlaces[idx] = [mainQueueContext executeFetchRequest:fetchRequest error:&fetchError];
            [self.tableView reloadData];
        }];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.indexedPlaces count];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMITMapIndexedPlaceCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kMITMapIndexedPlaceCellIdentifier];
    }
    NSArray *places = self.indexedPlaces[indexPath.section];
    MITMapPlace *place = places[indexPath.row];
    cell.textLabel.text = place.title;
    cell.detailTextLabel.text = place.subtitle;
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return MAX(0, floor((index + 1) / (float)(MITMapSectionIndexSeparatorDotCountForOrientation(self.interfaceOrientation) + 1)));
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MITMapCategory *childCategory = self.category.children[section];
    return childCategory.name;
}

@end
