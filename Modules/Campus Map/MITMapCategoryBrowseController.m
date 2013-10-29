#import "MITMapCategoryBrowseController.h"
#import "MITMapModel.h"
#import "CoreData+MITAdditions.h"

#import "MIT_MobileAppDelegate.h"
#import "MITCoreDataController.h"

typedef void (^MITMapCategorySelectionHandler)(MITMapCategory *category, NSOrderedSet *selectedPlaces);

static NSString* const MITMapCategoryViewAllText = @"View all on map";

@interface MITMapCategoryBrowseController ()
@property (nonatomic,strong) MITMapCategorySelectionHandler selectionBlock;

@property (nonatomic,strong) MITMapCategory *category;
@property (nonatomic,getter = isShowingCategories) BOOL showingCategories;

@property (nonatomic,strong) NSOrderedSet *categoriesContent;

- (id)initWithCategory:(MITMapCategory*)category;
@end

@implementation MITMapCategoryBrowseController
- (id)init:(MITMapCategorySelectionHandler)placesSelected
{
    self = [self init];
    if (self) {
        _selectionBlock = placesSelected;
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
    [super viewWillAppear:animated];

    // If the category is nil, show all the top level categories.
    // This also triggers a fetch for the categories from the data controller
    if (!self.category || [self.category hasSubcategories]) {
        self.showingCategories = YES;
    }


    if (self.isShowingCategories) {
        self.updateTableOnResultsChange = NO;

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
    } else {
        // A category was set. If the category has subcategories, we should
        // show the subcategories, otherwise, grab the list of places which belong to the
        // assigned category and show them.
        self.navigationItem.title = self.category.name;
        self.updateTableOnResultsChange = YES;

        __weak MITMapCategoryBrowseController *weakSelf = self;
        [[MITMapModelController sharedController] placesInCategory:self.category
                                                            loaded:^(NSOrderedSet *places, NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
                                                                MITMapCategoryBrowseController *blockSelf = weakSelf;
                                                                if (blockSelf && !error) {
                                                                    NSFetchRequest *displayRequest = [fetchRequest copy];

                                                                    if (![displayRequest.sortDescriptors count]) {
                                                                        displayRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
                                                                    }

                                                                    self.fetchRequest = displayRequest;
                                                                } else if (error) {
                                                                    DDLogWarn(@"Failed to fetch places in category '%@', %@", blockSelf.category.identifier, error);
                                                                }
                                                            }];
    }
}

- (void)didCompleteSelection:(NSOrderedSet*)selection withCategory:(MITMapCategory*)category
{
    if (self.selectionBlock) {
        self.selectionBlock(category,selection);
    }
}

- (IBAction)cancelItemTouched:(UIBarButtonItem*)doneItem
{
    [self didCompleteSelection:nil withCategory:nil];
}

- (IBAction)showAllButtonTouched:(UIButton*)showAllButton
{
    if (![self isShowingCategories]) {
        NSArray *sections = [self.fetchedResultsController sections];
        NSArray *places = [(id<NSFetchedResultsSectionInfo>)sections[0] objects];

        NSManagedObjectContext *mainContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
        NSOrderedSet *resolvedObjects = [NSOrderedSet orderedSetWithArray:[mainContext transferManagedObjects:places]];
        [self didCompleteSelection:resolvedObjects withCategory:self.category];
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (![self isShowingCategories]) {
        UIButton *showAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        showAllButton.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), 0);
        showAllButton.titleLabel.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
        showAllButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.95];
        showAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        showAllButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        showAllButton.contentEdgeInsets = UIEdgeInsetsMake(0, 8., 0 ,0);

        [showAllButton setImage:[UIImage imageNamed:@"global/action-map"] forState:UIControlStateNormal];

        [showAllButton setTitle:MITMapCategoryViewAllText forState:UIControlStateNormal];
        [showAllButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        showAllButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8., 0, 0.);

        [showAllButton addTarget:self
                          action:@selector(showAllButtonTouched:)
                forControlEvents:UIControlEventTouchUpInside];

        return showAllButton;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!self.isShowingCategories) {
        return [UIImage imageNamed:@"global/action-map"].size.height + 8.; // 8px inset on top and bottom of view
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isShowingCategories) {
        return [self.categoriesContent count];
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
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
        MITMapCategory *category = self.categoriesContent[indexPath.row];
        cell.textLabel.text = category.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        // Otherwise, we are showing a category's places
        MITMapPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text = place.name;
    }

    return cell;
}


#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isShowingCategories) {
        MITMapCategory *category = self.categoriesContent[indexPath.row];
        MITMapCategoryBrowseController *categoriesViewController = [[MITMapCategoryBrowseController alloc] initWithCategory:category];
        categoriesViewController.selectionBlock = self.selectionBlock;

        [self.navigationController pushViewController:categoriesViewController animated:YES];
    } else if (self.selectionBlock) {
        MITMapPlace *place = [self.fetchedResultsController objectAtIndexPath:indexPath];

        NSManagedObjectContext *mainContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
        MITMapPlace *mainPlace = (MITMapPlace*)[mainContext objectWithID:[place objectID]];
        [self didCompleteSelection:[NSOrderedSet orderedSetWithObject:mainPlace] withCategory:self.category];
    }
}

@end
