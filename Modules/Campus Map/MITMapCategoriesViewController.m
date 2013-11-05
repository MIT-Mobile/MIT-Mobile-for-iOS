#import "MITMapCategoriesViewController.h"
#import "MITAdditions.h"

#import "MITMapModel.h"
#import "CoreData+MITAdditions.h"

#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"
#import "MITMapPlacesViewController.h"

typedef void (^MITMapCategorySelectionHandler)(MITMapCategory *category, NSOrderedSet *selectedPlaces);

static NSString* const MITMapCategoryViewAllText = @"View all on map";

@interface MITMapCategoriesViewController ()
@property (nonatomic,strong) MITMapCategorySelectionHandler selectionBlock;

@property (nonatomic,strong) MITMapCategory *category;
@property (nonatomic,strong) NSOrderedSet *categoriesContent;

- (id)initWithCategory:(MITMapCategory*)category;
@end

@implementation MITMapCategoriesViewController
- (id)init:(MITMapCategorySelectionHandler)placesSelected
{
    self = [super init];
    if (self) {
        _selectionBlock = placesSelected;
    }

    return self;
}

- (id)initWithCategory:(MITMapCategory*)category
{
    self = [super init];
    if (self) {
        _category = category;
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationNone];

    if (!self.category) {
        // We are about to appear and we will be showing
        // the list of top-level categories. Stick the 'Cancel' button
        // here
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(cancelItemTouched:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
        self.navigationItem.title = @"Browse";


        if (!self.categoriesContent) {
            [[MITMapModelController sharedController] categories:^(NSOrderedSet *categories, NSError *error) {
                if (!error) {
                    if (![self.categoriesContent isEqualToOrderedSet:categories]) {
                        self.categoriesContent = categories;
                        [self.tableView reloadData];
                    }
                } else {
                    DDLogWarn(@"Failed to retreive category listing: %@",error);
                }
            }];
        }
    } else {
        self.navigationItem.title = self.category.name;
        self.categoriesContent = self.category.subcategories;
    }
}

- (void)didCompleteSelectionWithObjects:(NSOrderedSet*)selection inCategory:(MITMapCategory*)category
{
    NSMutableOrderedSet *objectIDs = [[NSMutableOrderedSet alloc] init];
    [selection enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSManagedObjectID class]]) {
            [objectIDs addObject:obj];
        } else if ([obj isKindOfClass:[NSManagedObject class]]) {
            [objectIDs addObject:[obj objectID]];
        }
    }];

    if (self.selectionBlock) {
        self.selectionBlock(category,objectIDs);
    }
}

- (IBAction)cancelItemTouched:(UIBarButtonItem*)doneItem
{
    [self didCompleteSelectionWithObjects:nil inCategory:nil];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.categoriesContent count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    // Use the older dequeue method here because we are using the UITableViewCellStyleSubtitle
    // style and not providing a subclass which overrides initWithStyle:reuseIdentifier:
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    MITMapCategory *category = self.categoriesContent[indexPath.row];
    cell.textLabel.text = category.name;

    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
    if ([selectedIndexPath isEqual:indexPath]) {
        UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView*)cell.accessoryView;

        if (!([indicatorView isKindOfClass:[UIActivityIndicatorView class]])) {
            indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            indicatorView.hidesWhenStopped = YES;

            cell.accessoryView = indicatorView;
        }

        cell.accessoryType = UITableViewCellAccessoryNone;
        [indicatorView startAnimating];
    } else {
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapCategory *category = self.categoriesContent[indexPath.row];

    if ([category hasSubcategories]) {
        MITMapCategoriesViewController *categoriesViewController = [[MITMapCategoriesViewController alloc] initWithCategory:category];
        categoriesViewController.selectionBlock = self.selectionBlock;

        [self.navigationController pushViewController:categoriesViewController animated:YES];
    } else {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        indicatorView.hidesWhenStopped = YES;
        [indicatorView startAnimating];
        cell.accessoryView = indicatorView;
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell sizeToFit];
        
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];

        __weak MITMapCategoriesViewController *weakSelf = self;
        MITMapModelController *modelController = [MITMapModelController sharedController];
        [modelController placesInCategory:category
                                   loaded:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
                                       MITMapCategoriesViewController *blockSelf = weakSelf;
                                       if (!error) {
                                           NSIndexPath *selectedRow = [tableView indexPathForSelectedRow];
                                           if ([selectedRow isEqual:indexPath]) {
                                               void (^selectionBlock)(NSOrderedSet*) = ^(NSOrderedSet *mapPlaces) {
                                                   MITMapCategoriesViewController *blockSelf = weakSelf;
                                                   [blockSelf didCompleteSelectionWithObjects:mapPlaces inCategory:category];
                                               };

                                               MITMapPlacesViewController *viewController = [[MITMapPlacesViewController alloc] initWithPredicate:fetchRequest.predicate
                                                                                                                                  sortDescriptors:fetchRequest.sortDescriptors
                                                                                                                                        selection:selectionBlock];
                                               [blockSelf.navigationController pushViewController:viewController animated:YES];
                                           }
                                       } else {
                                           [blockSelf didCompleteSelectionWithObjects:nil inCategory:nil];
                                       }

                                       [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                   }];
    }
}

@end
