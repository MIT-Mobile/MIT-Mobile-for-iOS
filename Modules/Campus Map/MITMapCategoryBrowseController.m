#import "MITMapCategoryBrowseController.h"
#import "MITMapModel.h"

@interface MITMapCategoryBrowseController ()
@property (nonatomic,copy) MITMapPlaceSelectionHandler selectionBlock;
@property (nonatomic,strong) MITMapCategory *category;
@property (nonatomic,copy) NSOrderedSet *dataSource;

- (id)initWithCategory:(MITMapCategory*)category;
- (BOOL)isShowingCategories;
- (BOOL)isShowingPlaces;
@end

@implementation MITMapCategoryBrowseController
- (id)init
{
    self = [super init];
    if (self) {

    }

    return self;
}

- (id)init:(MITMapPlaceSelectionHandler)placesSelected
{
    self = [self init];
    if (self) {
        _selectionBlock = [placesSelected copy];
    }

    return self;
}

- (id)initWithCategory:(MITMapCategory*)category
{
    self = [self init];
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
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(doneItemTouched:)];
    self.navigationItem.rightBarButtonItem = doneItem;

    if (!self.dataSource) {
        if (!self.category) {
            // No category given so display the top-level list of all the categories.
            self.navigationItem.title = @"Browse";

            [[MITMapModelController sharedController] categories:^(NSOrderedSet *objects, NSDate *lastUpdated, BOOL finished, NSError *error) {
                if (!error) {
                    if (![self.dataSource isEqualToOrderedSet:objects]) {
                        self.dataSource = objects;
                        [self.tableView reloadData];
                    }
                } else {
                    DDLogWarn(@"Failed to retreive category listing: %@",error);
                }
            }];
        } else if ([self.category hasSubcategories]) {
            self.navigationItem.title = self.category.name;
            self.dataSource = self.category.subcategories;
        } else {
            self.navigationItem.title = self.category.name;
            // We were provided with a category but it has no subcategories; pull the list of
            // places for the category from the server and dislpay
            [[MITMapModelController sharedController] placesInCategory:self.category
                                                                loaded:^(NSOrderedSet *objects, NSDate *lastUpdated, BOOL finished, NSError *error) {
                                                                    if (!error) {
                                                                        if (![self.dataSource isEqualToOrderedSet:objects]) {
                                                                            self.dataSource = objects;
                                                                            [self.tableView reloadData];
                                                                            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                                                                        }
                                                                    } else {
                                                                        DDLogWarn(@"Failed to retreive category listing: %@",error);
                                                                    }
                                                                }];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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

- (BOOL)isShowingCategories
{
    return (!self.category || [self.category hasSubcategories]);
}

- (BOOL)isShowingPlaces
{
    return (self.category && ![self.category hasSubcategories]);
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = [self.dataSource count];

    if ([self isShowingPlaces]) {
        // Increase the number of rows by 1 so we can display the 'Show all the things!' cell
        numberOfRows += 1;
    }

    return numberOfRows;
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


    if ([self isShowingCategories]) {
        MITMapCategory *category = self.dataSource[indexPath.row];
        cell.textLabel.text = category.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"View all on map";
        } else {
            NSInteger dataIndex = indexPath.row - 1;
            // Otherwise, we are showing a category's places
            MITMapPlace *place = self.dataSource[dataIndex];
            cell.textLabel.text = place.name;
        }
    }

    return cell;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isShowingCategories]) {
        MITMapCategory *category = self.dataSource[indexPath.row];
        MITMapCategoryBrowseController *categoriesViewController = [[MITMapCategoryBrowseController alloc] initWithCategory:category];
        categoriesViewController.selectionBlock = self.selectionBlock;

        [self.navigationController pushViewController:categoriesViewController animated:YES];
    } else if (self.selectionBlock) {
        NSOrderedSet *selectedObjects = nil;
        if (indexPath.row == 0) {
            selectedObjects = self.dataSource;
        } else {
            MITMapPlace *place = self.dataSource[indexPath.row - 1];
            selectedObjects = [NSOrderedSet orderedSetWithObject:place];
        }

        self.selectionBlock(selectedObjects,nil);
    }
}

@end
