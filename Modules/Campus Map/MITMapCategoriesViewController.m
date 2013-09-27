#import "MITMapCategoriesViewController.h"
#import "MITMapModelController.h"
#import "MITMapCategory.h"

@interface MITMapCategoriesViewController () <MITMapPlaceSelectionDelegate>

@end

@implementation MITMapCategoriesViewController
- (id)init
{
    return [self initWithSubcategoriesOfCategory:nil];
}

- (id)initWithSubcategoriesOfCategory:(MITMapCategory*)category
{
    self = [super init];
    if (self) {
        _categories = [category.subcategories copy];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(doneItemTouched:)];
    self.navigationItem.rightBarButtonItem = doneItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.categories) {
        [[MITMapModelController sharedController] placeCategories:^(NSOrderedSet *objects, NSDate *lastUpdated, BOOL finished, NSError *error) {
            if (!error) {
                if (![self.categories isEqualToOrderedSet:objects]) {
                    self.categories = objects;
                }
            } else {
                DDLogWarn(@"Failed to retreive category listing: %@",error);
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneItemTouched:(UIBarButtonItem*)doneItem
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.categories count];
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
    
    MITMapCategory *category = self.categories[indexPath.row];
    cell.textLabel.text = category.name;
    
    if ([category hasSubcategories]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITMapCategory *category = self.categories[indexPath.row];
    
    if ([category hasSubcategories]) {
        MITMapCategoriesViewController *categoriesViewController = [[MITMapCategoriesViewController alloc] initWithSubcategoriesOfCategory:category];
        categoriesViewController.placeSelectionDelegate = self;
        [self.navigationController pushViewController:categoriesViewController animated:YES];
    } else {
        if ([self.placeSelectionDelegate respondsToSelector:@selector(mapCategoriesPicker:didSelectPlace:)]) {
            [self.placeSelectionDelegate mapCategoriesPicker:self didSelectPlace:category];
        }
    }
}

#pragma mark MITMapPlaceSelectionDelegate
- (void)mapCategoriesPicker:(MITMapCategoriesViewController *)controller didSelectPlace:(id)place
{
    // Forward the notification up the chain.
    if ([self.placeSelectionDelegate respondsToSelector:@selector(mapCategoriesPicker:didSelectPlace:)]) {
        [self.placeSelectionDelegate mapCategoriesPicker:self didSelectPlace:place];
    }
}

#pragma mark - Dynamic Property Setters
- (void)setCategories:(NSOrderedSet*)categories
{
    [self setCategories:categories animated:NO];
}

- (void)setCategories:(NSOrderedSet *)categories animated:(BOOL)animated
{
    if (![_categories isEqualToOrderedSet:categories]) {
        NSOrderedSet *oldCategories = self.categories;
        _categories = [categories copy];
        
        if (animated) {
            [self animateTableUpdateFromCategories:oldCategories to:self.categories];
        } else {
            [self.tableView reloadData];
        }
    }
}

- (void)animateTableUpdateFromCategories:(NSOrderedSet*)oldCategories to:(NSOrderedSet*)newCategories
{
    NSMutableArray *updatedRows = [[NSMutableArray alloc] init];
    // Run through all of the old category objects and make a list of each one which
    //  has changed in the latest update (where a change is either an addition, deletion or move).
    // The list of NSIndexPaths generated here will be used to refresh the data later on
    [oldCategories enumerateObjectsUsingBlock:^(MITMapCategory *category, NSUInteger idx, BOOL *stop) {
        if (idx < [newCategories count]) {
            MITMapCategory *newCategory = oldCategories[idx];
            if (![category isEqual:newCategory]) {
                [updatedRows addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
            }
        } else {
            (*stop) = YES;
        }
    }];
    
    // If we have more
    if ([oldCategories count] < [newCategories count]) {
        NSRange reloadRange = NSMakeRange([oldCategories count], [newCategories count] - [oldCategories count]);
        [[NSIndexSet indexSetWithIndexesInRange:reloadRange] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [updatedRows addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        }];
    }
    
    [self.tableView reloadRowsAtIndexPaths:updatedRows withRowAnimation:UITableViewRowAnimationAutomatic];
}


@end
