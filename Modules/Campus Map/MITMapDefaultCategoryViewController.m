#import "MITMapDefaultCategoryViewController.h"
#import "MITMapModelController.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "UIKit+MITAdditions.h"

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0){
        return [self viewAllCell];
    }
    else{
        return [self categoryCellForIndex:indexPath.row - 1];
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

- (UITableViewCell *)categoryCellForIndex:(NSInteger)rowIndex
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCategoryTableCellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCategoryTableCellIdentifier];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    }
    
    MITMapPlace *place = self.placesInCategory[rowIndex];
    cell.textLabel.text = place.title;
    cell.detailTextLabel.text = place.subtitle;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0){
        [self.delegate placeSelectionViewController:self didSelectCategory:self.category places:self.placesInCategory];
    }
    else {
        MITMapPlace *place = self.placesInCategory[indexPath.row - 1];
        [self.delegate placeSelectionViewController:self didSelectPlace:place];
    }
}

@end
