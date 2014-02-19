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

static NSString* const MITNewsStoryCellIdentifier = @"StoryCell";
static NSString* const MITNewsStoryCellNibName = @"NewsStoryTableCell";

static NSString* const MITNewsStoryNoDekCellIdentifier = @"StoryNoDekCell";
static NSString* const MITNewsStoryNoDekCellNibName = @"NewsStoryNoDekTableCell";

static NSString* const MITNewsStoryExternalType = @"news_clip";
static NSString* const MITNewsStoryExternalCellIdentifier = @"StoryExternalCell";
static NSString* const MITNewsStoryExternalCellNibName = @"NewsStoryExternalTableCell";

static NSString* const MITNewsCategoryHeaderIdentifier = @"MITNewsCategoryHeader";
static NSString* const MITNewsStoryFeaturedStoriesRequestToken = @"MITNewsFeaturedStoriesRequest";

@interface MITNewsViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic) BOOL needsNavigationItemUpdate;
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,getter = isSearching) BOOL searching;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic,strong) NSMapTable *cachedStoriesByCategory;
@property (nonatomic,strong) NSMapTable *sizingCellsByIdentifier;

@property (nonatomic,strong) NSFetchedResultsController *featuredStoriesFetchedResultsController;
@property (nonatomic,strong) NSFetchedResultsController *categoriesFetchedResultsController;

@property (nonatomic,strong) NSString *searchQuery;
@property (nonatomic,strong) NSMutableArray *searchResults;

@property (nonatomic,readonly) MITNewsStory *selectedStory;

+ (NSDictionary*)headerTextAttributes;

- (void)loadFetchedResultsControllers;

- (void)setNeedsNavigationItemUpdate;
- (void)updateNavigationItemIfNeeded;
- (MITNewsStoryCell*)sizingCellForIdentifier:(NSString*)identifier;
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

    [self.tableView registerNib:[UINib nibWithNibName:@"NewsCategoryHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:MITNewsCategoryHeaderIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];

    self.gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    self.categoriesByGestureRecognizer = [NSMapTable weakToStrongObjectsMapTable];
    self.sizingCellsByIdentifier = [NSMapTable strongToWeakObjectsMapTable];
    
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
    
    // Only make sure the toolbar is visible if we are not searching
    // otherwise, returning after viewing a story pops it up
    if (!self.isSearching) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performDataUpdate:^(NSError *error){
        if (error) {
            [self setUpdateText:@"Update failed" animated:animated];
        }
        
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
            MITNewsStory *story = [self selectedStory];
            if (story) {
                NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                managedObjectContext.parentContext = self.managedObjectContext;
                storyDetailViewController.managedObjectContext = managedObjectContext;
                storyDetailViewController.story = (MITNewsStory*)[managedObjectContext objectWithID:[story objectID]];
            }
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

- (void)setNeedsNavigationItemUpdate
{
    self.needsNavigationItemUpdate = YES;
}


#pragma mark View Orientation
- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
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

#pragma mark - Managing states
#pragma mark Updating
- (void)setUpdating:(BOOL)updating
{
    [self setUpdating:updating animated:NO];
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

#pragma mark Navigation Item
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

#pragma mark Responding to UI events
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
}

- (IBAction)loadMoreFooterTapped:(id)sender
{
    __weak UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView*)self.searchDisplayController.searchResultsTableView.tableFooterView;
    
    if (footerView.textLabel.isEnabled) {
        NSString *query = self.searchQuery;
        NSUInteger offset = [self.searchResults count];
        
        footerView.textLabel.enabled = NO;
        
        __weak MITNewsViewController *weakSelf = self;
        [[MITNewsModelController sharedController] storiesInCategory:nil
                                                               query:query
                                                              offset:offset
                                                               limit:20
                                                          completion:^(NSArray *stories, MITResultsPager *pager, NSError *error) {
                                                              MITNewsViewController *blockSelf = weakSelf;
                                                              if (blockSelf && footerView) {
                                                                  NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(offset, [stories count])];
                                                                  [blockSelf.searchResults insertObjects:stories atIndexes:insertedIndexes];
                                                                  footerView.textLabel.enabled = YES;
                                                                  [blockSelf.searchDisplayController.searchResultsTableView reloadData];
                                                              }
                                                          }];
    }
}

#pragma mark Loading & updating, and retrieving data
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
        categories.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

        NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:categories
                                                                                                   managedObjectContext:self.managedObjectContext
                                                                                                     sectionNameKeyPath:nil
                                                                                                              cacheName:nil];
        fetchedResultsController.delegate = self;
        self.categoriesFetchedResultsController = fetchedResultsController;
    }
}

- (void)performDataUpdate:(void (^)(NSError *error))completion
{
    if (!self.isUpdating) {
        self.updating = YES;

        NSHashTable *inFlightDataRequests = [NSHashTable weakObjectsHashTable];
        __weak MITNewsViewController *weakSelf = self;
        MITNewsModelController *modelController = [MITNewsModelController sharedController];

        [inFlightDataRequests addObject:MITNewsStoryFeaturedStoriesRequestToken];
        [modelController featuredStoriesWithOffset:0
                                             limit:self.numberOfStoriesPerCategory
                                        completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                            MITNewsViewController *blockSelf = weakSelf;
                                            if (blockSelf) {
                                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                    [inFlightDataRequests removeObject:MITNewsStoryFeaturedStoriesRequestToken];

                                                    if ([inFlightDataRequests count] == 0) {
                                                        [blockSelf setUpdating:NO animated:YES];

                                                        if (completion) {
                                                            completion(error);
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
                                                            completion(error);
                                                        }
                                                    }
                                                }];
                                            }
                                        }];
            }];
        }];
    }
}

- (void)loadSearchResultsForQuery:(NSString*)query loaded:(void (^)(NSError *error))completion
{
    if ([query length] == 0) {
        self.searchQuery = nil;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.searchResults = [[NSMutableArray alloc] init];
            
            if (completion) {
                completion(nil);
            }
        }];
    }
    
    if (![self.searchQuery isEqualToString:query]) {
        NSString *currentQuery = self.searchQuery;
        
        MITNewsModelController *modelController = [MITNewsModelController sharedController];
        __weak MITNewsViewController *weakSelf = self;
        [modelController storiesInCategory:nil
                                     query:query
                                    offset:0
                                     limit:20
                                completion:^(NSArray* stories, MITResultsPager* pager, NSError* error) {
                                    MITNewsViewController *blockSelf = weakSelf;
                                    if (blockSelf && (blockSelf.searchQuery == currentQuery)) {
                                        blockSelf.searchQuery = query;
                                        
                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                            blockSelf.searchResults = [[NSMutableArray alloc] initWithArray:stories];

                                            if (completion) {
                                                completion(error);
                                            }
                                        }];
                                    }
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

- (MITNewsStory*)selectedStory
{
    UITableView *tableView = nil;

    if (self.searchDisplayController.isActive) {
        tableView = self.searchDisplayController.searchResultsTableView;
    } else {
        tableView = self.tableView;
    }

    NSIndexPath* selectedIndexPath = [tableView indexPathForSelectedRow];
    return [self storyAtIndexPath:selectedIndexPath inTableView:tableView];
}

- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath inTableView:(UITableView*)tableView
{
    NSUInteger section = (NSUInteger)indexPath.section;
    NSUInteger row = (NSUInteger)indexPath.row;

    if (tableView == self.tableView) {
        MITNewsStory *story = nil;

        if (self.showFeaturedStoriesSection && (section == 0)) {
            id<NSFetchedResultsSectionInfo> sectionInfo = [self.featuredStoriesFetchedResultsController sections][section];
            story = (MITNewsStory*)[sectionInfo objects][row];
        } else {
            if (self.showFeaturedStoriesSection) {
                section -= 1;
            }

            MITNewsCategory *sectionCategory = self.categoriesFetchedResultsController.fetchedObjects[section];
            NSArray *stories = [self storiesInCategory:sectionCategory];
            story = stories[row];
        }

        return story;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchResults[row];
    } else {
        return nil;
    }
}

- (NSString*)tableViewCellIdentifierForStory:(MITNewsStory*)story
{
    __block NSString *identifier = nil;
    if (story) {
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *newsStory = (MITNewsStory*)[self.managedObjectContext objectWithID:[story objectID]];

            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                identifier = MITNewsStoryExternalCellIdentifier;
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];
    }

    return identifier;
}


- (MITNewsStoryCell*)sizingCellForIdentifier:(NSString *)identifier
{
    MITNewsStoryCell *sizingCell = [self.sizingCellsByIdentifier objectForKey:identifier];

    if (!sizingCell) {
        UINib *cellNib = nil;
        if ([identifier isEqualToString:MITNewsStoryCellIdentifier]) {
            cellNib = [UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil];
        } else if ([identifier isEqualToString:MITNewsStoryNoDekCellIdentifier]) {
            cellNib = [UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil];
        } else if ([identifier isEqualToString:MITNewsStoryExternalCellIdentifier]) {
            cellNib = [UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil];
        }

        sizingCell = [[cellNib instantiateWithOwner:sizingCell options:nil] firstObject];
        sizingCell.hidden = YES;
        sizingCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.tableView addSubview:sizingCell];
        [self.sizingCellsByIdentifier setObject:sizingCell forKey:identifier];
    }

    sizingCell.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 84.);
    return sizingCell;
}

#pragma mark - NSFetchedResultsController
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Do nothing. Here so that change tracking is enabled for the NSFetchedResultsControllers
}

#pragma mark - UITableView
#pragma mark UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self respondsToSelector:@selector(setNeedsNavigationItemUpdate)]) {
        [self setNeedsNavigationItemUpdate];
    }
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
        MITDisclosureHeaderView *headerView = (MITDisclosureHeaderView*)[tableView dequeueReusableHeaderFooterViewWithIdentifier:MITNewsCategoryHeaderIdentifier];

        if (self.showFeaturedStoriesSection && (section == 0)) {
            headerView.titleLabel.text = @"Featured Stories";
            headerView.accessoryView.hidden = YES;

            UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
            if (recognizer) {
                [headerView removeGestureRecognizer:recognizer];
                [self.categoriesByGestureRecognizer removeObjectForKey:recognizer];
                [self.gestureRecognizersByView removeObjectForKey:headerView];
            }

            return headerView;
        } else {
            if (self.featuredStoriesFetchedResultsController) {
                section -= 1;
            }

            UIGestureRecognizer *recognizer = [self.gestureRecognizersByView objectForKey:headerView];
            if (!recognizer) {
                recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableSectionHeaderTapped:)];
                [headerView addGestureRecognizer:recognizer];
            }

            // Keep track of the gesture recognizers we create so we can remove
            // them later
            [self.gestureRecognizersByView setObject:recognizer forKey:headerView];

            NSArray *categories = [self.categoriesFetchedResultsController fetchedObjects];
            [self.categoriesByGestureRecognizer setObject:categories[section] forKey:recognizer];

            __block NSString *categoryName = nil;
            [self.managedObjectContext performBlockAndWait:^{
                MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[categories[section] objectID]];
                categoryName = category.name;
            }];

            headerView.titleLabel.text = categoryName;
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
    MITNewsStory *story = [self storyAtIndexPath:indexPath inTableView:tableView];

    if (story) {
        NSString *identifier = [self tableViewCellIdentifierForStory:story];
        MITNewsStoryCell *sizingCell = [self sizingCellForIdentifier:identifier];
        [self configureCell:sizingCell forStory:story];

        [sizingCell setNeedsLayout];
        [sizingCell layoutIfNeeded];

        CGSize rowSize = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

		return MAX(86.,ceil(rowSize.height));
    }

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showStoryDetail" sender:tableView];
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        NSInteger numberOfSections = 0;

        if (self.showFeaturedStoriesSection && self.featuredStoriesFetchedResultsController.fetchedObjects) {
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
    MITNewsStory *newsStory = [self storyAtIndexPath:indexPath inTableView:tableView];
    NSString *identifier = [self tableViewCellIdentifierForStory:newsStory];

    NSAssert(identifier,@"[%@] missing UITableViewCell identifier in %@",self,NSStringFromSelector(_cmd));

    MITNewsStoryCell *cell = (MITNewsStoryCell*)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self configureCell:cell forStory:newsStory];
    return cell;
}

- (void)configureCell:(UITableViewCell*)cell forStory:(MITNewsStory*)newsStory
{
    __block NSString *title = nil;
    __block NSString *dek = nil;
    __block NSURL *imageURL = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsStory *story = (MITNewsStory*)[self.managedObjectContext objectWithID:[newsStory objectID]];
        title = story.title;
        dek = story.dek;

        MITNewsImageRepresentation *representation = [story.coverImage bestRepresentationForSize:cell.imageView.bounds.size];
        imageURL = representation.url;
    }];


    MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
    if (title) {
        NSError *error = nil;
        NSString *titleContent = [title stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
        if (!titleContent) {
            DDLogWarn(@"failed to sanitize title, falling back to the original content: %@",error);
            titleContent = title;
        }

        storyCell.titleLabel.text = titleContent;
    } else {
        storyCell.titleLabel.text = nil;
    }

    if (dek) {
        NSError *error = nil;
        NSString *dekContent = [dek stringBySanitizingHTMLFragmentWithPermittedElementNames:nil error:&error];
        if (error) {
            DDLogWarn(@"failed to sanitize dek, falling back to the original content: %@",error);
            dekContent = dek;
        }

        storyCell.dekLabel.text = dekContent;
    } else {
        storyCell.dekLabel.text = nil;
    }
    

    if (imageURL) {
        [storyCell.storyImageView setImageWithURL:imageURL];
    } else {
        storyCell.storyImageView.image = nil;
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
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryTableCell" bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryNoDekTableCell" bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:@"NewsStoryExternalTableCell" bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
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
    self.searchResults = nil;
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
    NSString *searchQuery = searchBar.text;
    
    __weak UISearchDisplayController *searchDisplayController = self.searchDisplayController;
    searchDisplayController.searchResultsTableView.tableFooterView = nil;

    UIColor *textColor = nil;
    if ([self.view respondsToSelector:@selector(tintColor)]) {
        textColor = self.view.tintColor;
    } else {
        textColor = [UIColor MITTintColor];
    }

    [self loadSearchResultsForQuery:searchQuery loaded:^(NSError *error) {
        if (!searchDisplayController.searchResultsTableView.tableFooterView) {
            UITableViewHeaderFooterView* tableFooter = [[UITableViewHeaderFooterView alloc] init];
            tableFooter.frame = CGRectMake(0, 0, 320, 44);

            tableFooter.textLabel.textColor = textColor;
            tableFooter.textLabel.font = [UIFont boldSystemFontOfSize:16.];
            tableFooter.textLabel.text = @"Load more items...";

            UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadMoreFooterTapped:)];
            tapRecognizer.numberOfTapsRequired = 1;
            tapRecognizer.numberOfTouchesRequired = 1;
            [tableFooter addGestureRecognizer:tapRecognizer];
            [tableFooter sizeToFit];
            tableFooter.backgroundColor = [UIColor blueColor];
            searchDisplayController.searchResultsTableView.tableFooterView = tableFooter;
        }
        
        [searchDisplayController.searchResultsTableView reloadData];
    }];
}

@end
