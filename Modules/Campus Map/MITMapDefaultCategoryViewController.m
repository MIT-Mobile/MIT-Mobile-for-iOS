#import "MITMapDefaultCategoryViewController.h"
#import "MITMapModelController.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "UIKit+MITAdditions.h"
#import "MITMapPlaceCell.h"

static NSString *const kViewAllTableCellIdentifier = @"kViewAllTableCellIdentifier";
static NSString *const kCategoryTableCellIdentifier = @"kCategoryTableCellIdentifier";

@interface MITMapDefaultCategoryViewController ()

@property (nonatomic, strong) NSArray *placesInCategory;

@end

@implementation MITMapDefaultCategoryViewController

@synthesize delegate = _delegate;

- (instancetype)initWithCategory:(MITMapCategory *)category
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _category = category;
        [self updatePlacesInCategory];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.category.name;
    [self setupTableView];
}

- (void)setupTableView
{
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([MITMapPlaceCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kCategoryTableCellIdentifier];
}


- (void)updatePlacesInCategory
{
    [self showRefreshControlLoadingAnimation];
    [[MITMapModelController sharedController] placesInCategory:self.category loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        
        NSManagedObjectContext *context = [[MITCoreDataController defaultController] mainQueueContext];
        NSError *fetchError;
        
        NSArray *fetchResults = [context executeFetchRequest:fetchRequest error:&fetchError];
        if (!fetchError){
            self.placesInCategory = fetchResults;
            self.category.places = [NSSet setWithArray:fetchResults];
            [context save:nil];
            [self.tableView reloadData];
            [self hideRefreshControlLoadingAnimation];
        }
    }];
}

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.placesInCategory ? [self.placesInCategory count] + 1 : 0; // +1 for the View All Results Cell
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0){
        return 50.0;
    }
    
    return [MITMapPlaceCell heightForPlace:self.placesInCategory[indexPath.row - 1] tableViewWidth:self.tableView.frame.size.width accessoryType:UITableViewCellAccessoryNone];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0){
        return [self viewAllCell];
    }
    else{
        return [self categoryCellForIndexPath:indexPath];
    }
}

- (UITableViewCell *)viewAllCell
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kViewAllTableCellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kViewAllTableCellIdentifier];
        cell.textLabel.text = @"View All on Map";
        cell.textLabel.textColor = [UIColor mit_tintColor];
    }
    return cell;
}

- (UITableViewCell *)categoryCellForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *adjustedIndexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:0];
    MITMapPlaceCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCategoryTableCellIdentifier forIndexPath:adjustedIndexPath];
    [cell setPlace:self.placesInCategory[adjustedIndexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0){
        [self.delegate placeSelectionViewController:self didSelectCategory:self.category];
    }
    else {
        MITMapPlace *place = self.placesInCategory[indexPath.row - 1];
        [self.delegate placeSelectionViewController:self didSelectPlace:place];
    }
}

@end
