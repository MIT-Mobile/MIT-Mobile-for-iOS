#import "MITNewsViewController.h"
#import "MITCoreData.h"
#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsStoryViewController.h"
#import "MITNewsStoriesViewController.h"
#import "MITNewsModelController.h"
#import "MITNewsStoryCell.h"
#import "MITDisclosureHeaderView.h"
#import "UIImageView+WebCache.h"

#import "MITAdditions.h"

// The below values were pulled from the News storyboard.
// Either change them if the storyboard changes or find a way
// to dynamically extract them.
static const CGFloat MITNewsStoryCellMinimumHeight = 86.;
static const CGFloat MITNewsStoryCellMaximumTextWidth = 196.;
static const CGSize MITNewsStoryCellDefaultImageSize = {.width = 86., .height = 61.};

static NSString* const MITNewsStoryFeaturedStoriesToken = @"MITNewsFeaturedStories";

@interface MITNewsViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic) BOOL needsNavigationItemUpdate;
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,getter = isSearching) BOOL searching;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic,strong) NSMapTable *cachedStoriesByCategory;

@property (nonatomic,strong) NSFetchedResultsController *featuredStoriesFetchedResultsController;
@property (nonatomic,strong) NSFetchedResultsController *categoriesFetchedResultsController;

@property (nonatomic,strong) NSString *searchQuery;
@property (nonatomic,strong) NSMutableArray *searchResults;


+ (NSDictionary*)headerTextAttributes;
+ (NSDictionary*)titleTextAttributes;
+ (NSDictionary*)dekTextAttributes;

- (void)loadFetchedResultsControllers;

- (void)setNeedsNavigationItemUpdate;
- (void)updateNavigationItemIfNeeded;
@end

@implementation MITNewsViewController

#pragma mark UI Element text attributes
// TODO: Look for an alternate spot for these. UIAppearance or a utility class maybe?
// Figure out how much we are going to be reusing these
+ (NSDictionary*)headerTextAttributes
{
    return @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.],
             NSForegroundColorAttributeName: [UIColor darkTextColor]};
}

+ (NSDictionary*)titleTextAttributes
{
    return @{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.],
             NSForegroundColorAttributeName: [UIColor blackColor]};
}

+ (NSDictionary*)dekTextAttributes
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:12.],
             NSForegroundColorAttributeName: [UIColor blackColor]};
}

+ (NSDictionary*)updateItemTextAttributes
{
    return @{NSFontAttributeName: [UIFont systemFontOfSize:[UIFont smallSystemFontSize]],
             NSForegroundColorAttributeName: [UIColor blackColor]};
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil managedObjectContext:nil];
}


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil managedObjectContext:(NSManagedObjectContext*)context
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}


#pragma mark Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.numberOfStoriesPerCategory = 3;
    self.showFeaturedStoriesSection = YES;

    [self.tableView registerNib:[UINib nibWithNibName:@"NewsCategoryHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NewsCategoryHeader"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryTableCell" bundle:nil] forCellReuseIdentifier:@"StoryCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryNoDekTableCell" bundle:nil] forCellReuseIdentifier:@"StoryNoDekCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NewsStoryExternalTableCell" bundle:nil] forCellReuseIdentifier:@"StoryExternalCell"];

    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];
    
    self.tableView.tableHeaderView = self.searchDisplayController.searchBar;
    
    CGPoint offset = self.tableView.contentOffset;
    offset.y = CGRectGetMaxY(self.searchDisplayController.searchBar.frame);
    self.tableView.contentOffset = offset;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self loadFetchedResultsControllers];

    NSError *fetchError = nil;
    [self.featuredStoriesFetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
    }

    fetchError = nil;
    [self.categoriesFetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        DDLogWarn(@"[%@] error while executing fetch: %@",NSStringFromClass([self class]),fetchError);
    }

    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performDataUpdate:^{
        DDLogVerbose(@"Update completed!");
        [self.tableView reloadData];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationViewController = [segue destinationViewController];

    DDLogVerbose(@"Performing segue with identifier '%@'",[segue identifier]);

    if ([segue.identifier isEqualToString:@"showStoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoryViewController class]]) {
            MITNewsStoryViewController *storyDetailViewController = (MITNewsStoryViewController*)destinationViewController;

            NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
            MITNewsStory *story = [self storyAtIndexPath:selectedIndexPath];

            NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            managedObjectContext.parentContext = self.managedObjectContext;
            storyDetailViewController.managedObjectContext = managedObjectContext;
            storyDetailViewController.story = (MITNewsStory*)[managedObjectContext objectWithID:[story objectID]];
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else if ([segue.identifier isEqualToString:@"showCategoryDetail"]) {
        if ([destinationViewController isKindOfClass:[MITNewsStoriesViewController class]]) {
            MITNewsStoriesViewController *storiesViewController = (MITNewsStoriesViewController*)destinationViewController;

            UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer*)sender;
            MITNewsCategory *category = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];

            NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] mainQueueContext];
            storiesViewController.managedObjectContext = managedObjectContext;
            storiesViewController.category = (MITNewsCategory*)[managedObjectContext objectWithID:[category objectID]];
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoriesViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

#pragma mark Notifications
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateNavigationItemIfNeeded];
}

- (void)updateNavigationItemIfNeeded
{
    if (self.needsNavigationItemUpdate) {
        UIScrollView *tableView = self.tableView;
        
        CGRect visibleRect = tableView.bounds;
        visibleRect.origin.x = tableView.contentOffset.x + tableView.contentInset.left;
        visibleRect.origin.y = tableView.contentOffset.y + tableView.contentInset.top;
            
        CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
        BOOL searchBarIsVisible = CGRectIntersectsRect(visibleRect, searchBarFrame);

        if (searchBarIsVisible) {
            if (self.navigationItem.rightBarButtonItem) {
                [self.navigationItem setRightBarButtonItem:nil animated:YES];
            }
        } else {
            if (!self.navigationItem.rightBarButtonItem) {
                UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                            target:self
                                                                                            action:@selector(searchButtonTapped:)];
                [self.navigationItem setRightBarButtonItem:searchItem animated:YES];
            }
        }
        self.needsNavigationItemUpdate = NO;
    }
}

- (void)setNeedsNavigationItemUpdate
{
    self.needsNavigationItemUpdate = YES;
}


#pragma mark View Orientation
- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Property Setters & Getters
- (NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext) {
        DDLogWarn(@"[%@] A managed object context was not set before being added to the view hierarchy. The default main queue NSManaged object context will be used but this will be a fatal error in the future.",self);
        _managedObjectContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
    }

    NSAssert(_managedObjectContext, @"[%@] failed to load a valid NSManagedObjectContext", NSStringFromClass([self class]));
    return _managedObjectContext;
}

#pragma mark Updating state
- (void)setUpdating:(BOOL)updating
{
    [self setUpdating:updating animated:YES];
}

- (void)setUpdating:(BOOL)updating animated:(BOOL)animated
{
    if (_updating != updating) {
        if (updating) {
            [self willBeginUpdating:animated];
        }

        _updating = updating;

        if (!_updating) {
            [self didEndUpdating:animated];
        }

    }
}

- (void)willBeginUpdating:(BOOL)animated
{
    [self setUpdateText:@"Updating..." animated:animated];
}

- (void)didEndUpdating:(BOOL)animated
{
    NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:[NSDate date]
                                                                        toDate:[NSDate date]];
    NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
    [self setUpdateText:updateText animated:animated];
}

- (void)setUpdateText:(NSString*)string animated:(BOOL)animated
{
    UILabel *updatingLabel = [[UILabel alloc] init];
    updatingLabel.attributedText = [[NSAttributedString alloc] initWithString:string attributes:[MITNewsViewController updateItemTextAttributes]];
    updatingLabel.backgroundColor = [UIColor clearColor];
    [updatingLabel sizeToFit];

    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark UI Events
- (IBAction)tableSectionHeaderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    MITNewsCategory *category = [self.categoriesByGestureRecognizer objectForKey:gestureRecognizer];

    if (category) {
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsCategory *localCategory = (MITNewsCategory*)[self.managedObjectContext objectWithID:[category objectID]];
            DDLogVerbose(@"Recieved tap on section header for category with name '%@'",localCategory.name);
        }];

        [self performSegueWithIdentifier:@"showCategoryDetail" sender:gestureRecognizer];
    }

}

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender
{
    CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
    searchBarFrame.size = CGSizeMake(1, 1);
    
    [self.tableView scrollRectToVisible:searchBarFrame animated:NO];
    [self.searchDisplayController.searchBar becomeFirstResponder];
    //[self.searchDisplayController setActive:YES animated:YES];
}

#pragma mark Table data helpers
- (void)loadFetchedResultsControllers
{
    // Featured fetched results controller
    if (self.showFeaturedStoriesSection && !self.featuredStoriesFetchedResultsController) {
        NSFetchRequest *featuredStories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        featuredStories.predicate = [NSPredicate predicateWithFormat:@"featured == YES"];
        featuredStories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                            [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:featuredStories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.featuredStoriesFetchedResultsController = fetchedResultsController;
    }

    if (!self.categoriesFetchedResultsController) {
        NSFetchRequest *categories = [NSFetchRequest fetchRequestWithEntityName:[MITNewsCategory entityName]];
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.categoriesFetchedResultsController = fetchedResultsController;
    }
}

- (void)performDataUpdate:(void (^)(void))completion;
{
    if (!self.isUpdating) {
        self.updating = YES;

        NSHashTable *inFlightDataRequests = [NSHashTable weakObjectsHashTable];
        __weak MITNewsViewController *weakSelf = self;
        MITNewsModelController *modelController = [MITNewsModelController sharedController];

        [inFlightDataRequests addObject:MITNewsStoryFeaturedStoriesToken];
        [modelController featuredStoriesWithOffset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            MITNewsViewController *blockSelf = weakSelf;
                                            if (blockSelf) {
                                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                    [inFlightDataRequests removeObject:MITNewsStoryFeaturedStoriesToken];

                                                    if ([inFlightDataRequests count] == 0) {
                                                        [blockSelf setUpdating:NO animated:YES];

                                                        if (completion) {
                                                            completion();
                                                        }
                                                    }
                                                }];
                                            }
                                        }];

        [modelController categories:^(NSArray *categories, NSError *error) {
            [categories enumerateObjectsUsingBlock:^(MITNewsCategory *category, NSUInteger idx, BOOL *stop) {
                [inFlightDataRequests addObject:category];

                [modelController storiesInCategory:category.identifier
                                             query:nil
                                            offset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            MITNewsViewController *blockSelf = weakSelf;
                                            if (blockSelf) {
                                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                    [inFlightDataRequests removeObject:category];

                                                    if ([inFlightDataRequests count] == 0) {
                                                        [blockSelf setUpdating:NO animated:YES];

                                                        if (completion) {
                                                            completion();
                                                        }
                                                    }
                                                }];
                                            }
                                        }];
            }];
        }];
    }
}


- (NSArray*)storiesInCategory:(MITNewsCategory*)category
{
    if (!self.cachedStoriesByCategory) {
        self.cachedStoriesByCategory = [NSMapTable weakToStrongObjectsMapTable];
    }

    NSArray *cachedStories = [self.cachedStoriesByCategory objectForKey:category];

    if (!cachedStories) {
        __block NSArray *stories = nil;
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];

        [self.managedObjectContext performBlockAndWait:^{
            MITNewsCategory *blockCategory = (MITNewsCategory*)[self.managedObjectContext objectWithID:[category objectID]];
            stories = [blockCategory.stories sortedArrayUsingDescriptors:sortDescriptors];
        }];

        [self.cachedStoriesByCategory setObject:stories forKey:category];
        cachedStories = stories;
    }

    return cachedStories;
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *story = nil;

    if (self.showFeaturedStoriesSection && (indexPath.section == 0)) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.featuredStoriesFetchedResultsController sections][indexPath.section];
        story = (MITNewsStory*)[sectionInfo objects][indexPath.row];
    } else {
        NSInteger categoryIndex = indexPath.section;
        if (self.showFeaturedStoriesSection) {
            categoryIndex -= 1;
        }

        MITNewsCategory *sectionCategory = self.categoriesFetchedResultsController.fetchedObjects[categoryIndex];
        NSArray *stories = [self storiesInCategory:sectionCategory];
        story = stories[indexPath.row];
    }

    return story;
}

#pragma mark - NSFetchedResultsController
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{

}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{

}

#pragma mark - UITableView
#pragma mark UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setNeedsNavigationItemUpdate];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 22.;
    } else {
        return 44.;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsCategoryHeader"];
        UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
        if (recognizer) {
            [headerView removeGestureRecognizer:recognizer];
            [self.categoriesByGestureRecognizer removeObjectForKey:recognizer];
            [self.gestureRecognizersByView removeObjectForKey:headerView];
        }

        if (self.showFeaturedStoriesSection && (section == 0)) {
            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Featured Stories"
                                                                                  attributes:[MITNewsViewController headerTextAttributes]];
            headerView.accessoryView.hidden = YES;

            return headerView;
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            UIGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];
            [headerView addGestureRecognizer:gesture];

            // Keep track of the gesture recognizers we create so we can remove
            // them later
            [self.gestureRecognizersByView setObject:gesture forKey:headerView];

            NSArray *categories = [self.categoriesFetchedResultsController fetchedObjects];
            [self.categoriesByGestureRecognizer setObject:categories[section] forKey:gesture];

            __block NSString *categoryName = nil;
            [self.managedObjectContext performBlockAndWait:^{
                MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[categories[section] objectID]];
                categoryName = category.name;
            }];

            headerView.textLabel.attributedText = [[NSAttributedString alloc] initWithString:categoryName
                                                                                  attributes:[MITNewsViewController headerTextAttributes]];

            headerView.accessoryView.hidden = NO;
            return headerView;
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (self.searchQuery) {
            UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NewsSearchHeader"];
            
            if (!headerView) {
                headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"NewsSearchHeader"];
            }
            
            headerView.textLabel.text = [NSString stringWithFormat:@"results for '%@'",self.searchQuery];
            return  headerView;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        [storyCell.storyImageView cancelCurrentImageLoad];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *story = nil;
    if (tableView == self.tableView) {
        story = [self storyAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        story = self.searchResults[indexPath.row];
    }

    if (story) {
        __block NSString *title = nil;
        __block NSString *dek = nil;

        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *blockStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
            title = blockStory.title;
            dek = blockStory.dek;
        }];

        CGFloat titleHeight = 0.;
        if ([title length]) {
            NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:story.title attributes:[MITNewsViewController titleTextAttributes]];

            CGRect titleRect = [titleString boundingRectWithSize:CGSizeMake(MITNewsStoryCellMaximumTextWidth, CGFLOAT_MAX)
                                                         options:(NSStringDrawingUsesFontLeading |
                                                                  NSStringDrawingUsesLineFragmentOrigin)
                                                         context:nil];
            titleHeight = ceil(CGRectGetHeight(titleRect));
        }

        CGFloat dekHeight = 0.;
        if ([dek length]) {
            NSAttributedString *dekString = [[NSAttributedString alloc] initWithString:story.dek attributes:[MITNewsViewController dekTextAttributes]];
            CGRect dekRect = [dekString boundingRectWithSize:CGSizeMake(MITNewsStoryCellMaximumTextWidth, CGFLOAT_MAX)
                                                     options:(NSStringDrawingUsesFontLeading |
                                                              NSStringDrawingUsesLineFragmentOrigin)
                                                     context:nil];
            dekHeight = ceil(CGRectGetHeight(dekRect));
        }

        CGFloat totalVerticalPadding = 23.;
        if ((titleHeight >= 1) && (dekHeight >= 1)) {
            totalVerticalPadding += 4.;
        }

        return MAX(MITNewsStoryCellMinimumHeight,titleHeight + dekHeight + totalVerticalPadding);
    } else {
        return UITableViewAutomaticDimension;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showStoryDetail" sender:self];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        NSInteger numberOfSections = 0;

        if (self.showFeaturedStoriesSection) {
            numberOfSections += 1;
        }

        numberOfSections += [self.categoriesFetchedResultsController.fetchedObjects count];
        return numberOfSections;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? 1 : 0);
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        if (self.showFeaturedStoriesSection && (section == 0)) {
            NSArray *stories = [self.featuredStoriesFetchedResultsController fetchedObjects];
            return MIN(self.numberOfStoriesPerCategory,[stories count]);
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            MITNewsCategory *category = self.categoriesFetchedResultsController.fetchedObjects[section];
            NSArray *storiesInCategory = [self storiesInCategory:category];
            return MIN(self.numberOfStoriesPerCategory,[storiesInCategory count]);
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? [self.searchResults count] : 0);
    }

    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MITNewsStory *story = nil;
    if (tableView == self.tableView) {
        story = [self storyAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        story = self.searchResults[indexPath.row];
    }

    if (story) {
        // TODO: Add logic to handle the StoryExternalCell.
        //  Right now there is no way to determine which cells are
        //  external so they'll just appear as StoryCells with
        //  no title, a dek and an image.
        // (2014.01.22 - bskinner)
        __block NSString *identifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *blockStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
            if ([blockStory.dek length])  {
                identifier = @"StoryCell";
            } else {
                identifier = @"StoryNoDekCell";
            }
        }];

        MITNewsStoryCell *cell = (MITNewsStoryCell*)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        [self configureCell:cell forRowAtIndexPath:indexPath tableView:tableView];
        return cell;
    } else {
        return nil;
    }
}

- (void)configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView*)tableView
{
    MITNewsStory *story = nil;
    if (tableView == self.tableView) {
        story = [self storyAtIndexPath:indexPath];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        story = self.searchResults[indexPath.row];
    }


    __block NSString *title = nil;
    __block NSString *dek = nil;
    __block NSURL *imageURL = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsStory *blockStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];
        title = blockStory.title;
        dek = blockStory.dek;
        MITNewsImageRepresentation *representation = [blockStory.coverImage bestRepresentationForSize:MITNewsStoryCellDefaultImageSize];
        imageURL = representation.url;
    }];


    MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
    storyCell.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:title
                                                                          attributes:[MITNewsViewController titleTextAttributes]];

    if ([dek length]) {
        storyCell.dekLabel.attributedText = [[NSAttributedString alloc] initWithString:dek
                                                                            attributes:[MITNewsViewController dekTextAttributes]];
    }

    if (imageURL) {
        [storyCell.storyImageView setImageWithURL:imageURL];
    }
}

#pragma mark - UISearchDisplayController
#pragma mark UISearchDisplayDelegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    self.searching = YES;
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:@"NewsCategoryHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"NewsCategoryHeader"];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryTableCell" bundle:nil] forCellReuseIdentifier:@"StoryCell"];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryNoDekTableCell" bundle:nil] forCellReuseIdentifier:@"StoryNoDekCell"];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryExternalTableCell" bundle:nil] forCellReuseIdentifier:@"StoryExternalCell"];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [tableView reloadData];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.searching = NO;
    [self.searchResults removeAllObjects];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if ([searchString length] == 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSString *queryString = searchBar.text;
    
    if (![self.searchQuery isEqualToString:searchBar.text]) {
        [self.searchResults removeAllObjects];
        self.searchQuery = queryString;
        
        __weak UISearchDisplayController *searchDisplayController = self.searchDisplayController;
        [[MITNewsModelController sharedController] storiesInCategory:nil
                                                               query:queryString
                                                              offset:0
                                                               limit:20
                                                          completion:^(NSArray *stories, MITResultsPager *pager, NSError *error) {
                                                              if ([self.searchQuery isEqualToString:queryString]) {
                                                                  if (searchDisplayController.isActive) {
                                                                      self.searchResults = [NSMutableArray arrayWithArray:stories];
                                                                      [searchDisplayController.searchResultsTableView reloadData];
                                                                  }
                                                              }
                                                          }];
    }
}

@end
