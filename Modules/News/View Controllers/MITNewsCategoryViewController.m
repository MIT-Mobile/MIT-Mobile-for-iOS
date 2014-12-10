#import <objc/runtime.h>

#import "MITNewsCategoryViewController.h"
#import "MITNewsStoryCell.h"
#import "MITCoreData.h"

#import "MITAdditions.h"
#import "MITDisclosureHeaderView.h"

#import "MITNewsModelController.h"
#import "MITNewsImage.h"
#import "MITNewsStoryViewController.h"
#import "MITNewsImageRepresentation.h"

#import "MITNewsCategory.h"
#import "MITNewsStory.h"

#import "UIImageView+WebCache.h"
#import "MITLoadingActivityView.h"
#import "MITNewsConstants.h"
#import "MITNewsLoadMoreTableViewCell.h"
#import "UITableView+DynamicSizing.h"

static NSString* const MITNewsCachedLayoutCellsAssociatedObjectKey = @"MITNewsCachedLayoutCellsAssociatedObject";

@interface MITNewsCategoryViewController () <UITableViewDataSourceDynamicSizing,NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate,UIAlertViewDelegate>
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,strong) NSDate *lastUpdated;

@property (nonatomic,getter = isSearching) BOOL searching;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic,strong) NSMapTable *sizingCellBy;

@property (nonatomic,strong) NSString *searchQuery;

#pragma mark Table data sources
@property (nonatomic) NSUInteger numberOfStoriesPerPage;
@property (nonatomic,strong) NSArray *searchResults;
@property (nonatomic,strong) NSArray *newsStories;

@property (nonatomic,readonly) MITNewsStory *selectedStory;
@property (nonatomic,strong) MITNewsCategory *category;

- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender;

#pragma mark Updating
- (void)beginUpdatingAnimated:(BOOL)animate;
- (void)endUpdatingAnimated:(BOOL)animate;
- (void)endUpdatingWithError:(NSError*)error animated:(BOOL)animate;
- (void)setToolbarString:(NSString*)string animated:(BOOL)animated;

#pragma mark UITableView Data Source Help
@end

@interface MITNewsCategoryViewController (NewsSearching)
// These methods are in the order they will (at least, should) be called in
- (void)beginSearchingAnimated:(BOOL)animated;
- (void)willLoadSearchResultsAnimated:(BOOL)animate;

- (void)loadStoriesForQuery:(NSString*)query loaded:(void (^)(NSString *query, NSError *error))completion;
- (void)loadStoriesForQuery:(NSString*)query shouldLoadNextPage:(BOOL)loadNextPage completion:(void (^)(NSString *query, NSError *error))completion;

- (void)didLoadResultsForSearchWithError:(NSError*)error animated:(BOOL)animate;
- (void)endSearchingAnimated:(BOOL)animated;

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView;
- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller;
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString;
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;
@end

@implementation MITNewsCategoryViewController {
    NSManagedObjectID *_categoryObjectID;

    CGPoint _contentOffsetToRestoreAfterSearching;
    id _storySearchInProgressToken;
    id _storyUpdateInProgressToken;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)hidesBottomBarWhenPushed
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalNoImageCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalNoImageCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];
    
    if (self.numberOfStoriesPerPage == 0) {
        self.numberOfStoriesPerPage = MITNewsDefaultNumberOfStoriesPerPage;
    }
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlWasTriggered:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.isSearching) {
        __block NSString *title = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if (self.category) {
                title = self.category.name;
            } else {
                title = @"Top Stories";
            }
        }];
        
        self.title = title;
        if (!self.newsStories) {
            __weak MITNewsCategoryViewController *weakSelf = self;
            [self fetchFirstPageOfStoriesForCurrentCategory:^{
                MITNewsCategoryViewController *blockSelf = weakSelf;
                if (blockSelf) {
                    [blockSelf.tableView reloadData];
                }
            }];
        }
        
        if (self.lastUpdated) {
            NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdated
                                                                                toDate:[NSDate date]];
            NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
            [self setToolbarString:updateText animated:NO];
        }

        // Only make sure the toolbar is visible if we are not searching
        // otherwise, returning after viewing a story pops it up
        [self.navigationController setToolbarHidden:NO animated:animated];

        if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
            self.navigationController.toolbar.barStyle = UIBarStyleBlack;
            self.navigationController.toolbar.translucent = NO;
        }
    }
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
                storyDetailViewController.story = story;
            }
        } else {
            DDLogWarn(@"unexpected class for segue %@. Expected %@ but got %@",segue.identifier,
                      NSStringFromClass([MITNewsStoryViewController class]),
                      NSStringFromClass([[segue destinationViewController] class]));
        }
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setter/Getter Implementations
- (NSMapTable*)gestureRecognizersByView
{
    if (!_gestureRecognizersByView) {
        _gestureRecognizersByView = [NSMapTable weakToWeakObjectsMapTable];
    }
    
    return _gestureRecognizersByView;
}

#pragma mark Category Management
- (MITNewsCategory*)category
{
    if (!_category) {
        if (_managedObjectContext && _categoryObjectID) {
            _category = (MITNewsCategory*)[_managedObjectContext objectWithID:_categoryObjectID];
        }
    }
    
    return _category;
}

- (void)setCategoryWithObjectID:(NSManagedObjectID *)objectID
{
    if (_categoryObjectID != objectID) {
        _categoryObjectID = objectID;
        
        [self didChangeCategory];
    }
}

- (void)didChangeCategory
{
    _category = nil;
    
    if (self.category && self.isViewLoaded && self.view.superview) {
        __weak MITNewsCategoryViewController *weakSelf = self;
        [self fetchFirstPageOfStoriesForCurrentCategory:^{
            MITNewsCategoryViewController *blockSelf = weakSelf;
            if (blockSelf) {
                [self.tableView reloadData];
            }
        }];
    }
}

#pragma mark - Managing states
#pragma mark Updating
- (void)beginUpdatingAnimated:(BOOL)animate
{
    if (!self.isUpdating) {
        self.updating = YES;
        
        if (!self.isSearching) {
            [self.refreshControl beginRefreshing];
            [self setToolbarString:@"Updating..." animated:animate];
        }
    }
}

- (void)endUpdatingAnimated:(BOOL)animate
{
    [self endUpdatingWithError:nil animated:animate];
}

- (void)endUpdatingWithError:(NSError*)error animated:(BOOL)animate
{
    if (self.isUpdating) {
        self.updating = NO;
        self.lastUpdated = [NSDate date];

        if (!self.isSearching) {
            if (!error) {
                NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:self.lastUpdated
                                                                                    toDate:[NSDate date]];
                NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
                [self setToolbarString:updateText animated:animate];
            } else {
                [self setToolbarString:@"Update Failed" animated:animate];
            }
            
            [self.refreshControl endRefreshing];
        }

    }
}


#pragma mark UI Helper
- (void)setToolbarString:(NSString*)string animated:(BOOL)animated
{
    UILabel *updatingLabel = [[UILabel alloc] init];
    updatingLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    updatingLabel.text = string;

    if (self.navigationController.toolbar.barStyle == UIBarStyleBlack) {
        updatingLabel.textColor = [UIColor whiteColor];
    } else {
        updatingLabel.textColor = [UIColor blackColor];
    }

    updatingLabel.backgroundColor = [UIColor clearColor];
    [updatingLabel sizeToFit];

    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark Responding to UI events
- (IBAction)searchButtonTapped:(UIBarButtonItem*)sender
{
    [self beginSearchingAnimated:NO];
}

- (IBAction)refreshControlWasTriggered:(UIRefreshControl*)sender
{
    __weak MITNewsCategoryViewController *weakSelf = self;
    [self loadStoriesInCategory:self.category
             shouldLoadNextPage:NO
                     completion:^(NSManagedObjectID *categoryID, NSError *error) {
                         MITNewsCategoryViewController *blockSelf = weakSelf;
                         if (blockSelf) {
                             [blockSelf.tableView reloadData];
                         }
                     }];
}

#pragma mark Loading & updating, and retrieving data
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
        
        [self didChangeManagedObjectContext];
    }
}

- (void)didChangeManagedObjectContext
{
    if (self.isSearching) {
        if (self.searchResults && self.managedObjectContext) {
            self.searchResults = [self.managedObjectContext transferManagedObjects:self.searchResults];
        } else {
            self.searchResults = nil;
        }
        
        [self.searchDisplayController.searchResultsTableView reloadData];
    } else {
        if (self.newsStories) {
            self.newsStories = [self.managedObjectContext transferManagedObjects:self.newsStories];
        } else {
            self.newsStories = nil;
        }
        
        [self.tableView reloadData];
    }
}


// The completion block will be called at least once, and may be called twice
// (first to display any current stories and then to display the updated results,
//  if an update was necessary)
- (void)fetchFirstPageOfStoriesForCurrentCategory:(void (^)(void))completion
{
    // nil out the update in progress token so that when the request returns
    // it skips its update (since we'll be messing with the data source)
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
    
    if (_categoryObjectID) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@",_categoryObjectID];
    }
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:NO]];
    fetchRequest.fetchLimit = self.numberOfStoriesPerPage;
    fetchRequest.fetchOffset = 0;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        NSArray *results = nil;
        NSUInteger objectCount = [self.managedObjectContext countForFetchRequest:fetchRequest error:nil];
        
        results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"failed to fetch stories from CoreData cache: %@",error);
            objectCount = NSNotFound;
        } else {
            self.newsStories = results;
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (completion) {
                completion();
            }
        }];

        BOOL shouldReloadStories = ((objectCount == NSNotFound) ||
                                    (objectCount < self.numberOfStoriesPerPage) ||
                                    (self.lastUpdated == nil));
        
        if (shouldReloadStories) {
            [self loadStoriesInCategory:self.category
                     shouldLoadNextPage:NO
                             completion:^(NSManagedObjectID *categoryID, NSError *error) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
    }];
}

- (void)loadStoriesInCategory:(MITNewsCategory*)newsCategory shouldLoadNextPage:(BOOL)shouldLoadNextPage completion:(void (^)(NSManagedObjectID *category,NSError *error))completion
{
    if (_storyUpdateInProgressToken) {
        DDLogWarn(@"there appears to be an request already in progress; it will be ignored");
    }
    
    __block NSString *categoryIdentifier = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[newsCategory objectID]];
        categoryIdentifier = category.identifier;
    }];

    NSUInteger offset = 0;
    if (shouldLoadNextPage) {
        offset = [self.newsStories count];
    }

    NSUUID *requestUUID = [NSUUID UUID];
    _storyUpdateInProgressToken = requestUUID;

    [self beginUpdatingAnimated:YES];
    
    __weak MITNewsCategoryViewController *weakSelf = self;
    void (^requestCompletionBlock)(NSArray*, NSDictionary*, NSError*error) = ^(NSArray *stories, NSDictionary* pagingMetadata, NSError *error) {
        MITNewsCategoryViewController *blockSelf = weakSelf;
        if (blockSelf) {
            BOOL isSameRequestToken = (blockSelf->_storyUpdateInProgressToken == requestUUID);
            
            if (isSameRequestToken) {
                _storyUpdateInProgressToken = nil;

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (!error) {
                        __block NSArray *localStories = nil;
                        [blockSelf.managedObjectContext performBlockAndWait:^{
                            localStories = [blockSelf.managedObjectContext transferManagedObjects:stories];
                        }];
                        
                        // If we are loading the next (or additional pages, in general)
                        // we should append the results onto the existing search results.
                        // Otherwise, just do a wholesale replacement of the content.
                        if (shouldLoadNextPage) {
                            NSMutableArray *updatedNewsStories = [NSMutableArray arrayWithArray:self.newsStories];
                            NSRange insertionRange = NSMakeRange(offset, [stories count]);
                            NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:insertionRange];
                            
                            if (offset < [updatedNewsStories count]) {
                                [updatedNewsStories removeObjectsInRange:NSMakeRange(offset, [updatedNewsStories count])];
                            }
                            
                            [updatedNewsStories insertObjects:stories atIndexes:insertedIndexes];
                            blockSelf.newsStories = updatedNewsStories;
                        } else {
                            blockSelf.newsStories = localStories;
                        }
                        
                        [self endUpdatingAnimated:YES];
                        
                        if (completion) {
                            completion([newsCategory objectID],nil);
                        }
                    } else {
                        [self endUpdatingWithError:error animated:YES];
                        
                        if (completion) {
                            completion(nil,error);
                        }
                    }
                }];
            }
        }
    };

    self.updating = YES;
    [self.refreshControl beginRefreshing];
    [[MITNewsModelController sharedController] storiesInCategory:categoryIdentifier
                                                           query:nil
                                                          offset:offset
                                                           limit:20
                                                      completion:requestCompletionBlock];
    
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
    return [self tableView:tableView representedObjectForRowAtIndexPath:selectedIndexPath];
}

#pragma mark - UITableView

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
        MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
        [storyCell.storyImageView sd_cancelCurrentImageLoad];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
    
    // Go for the low-hanging fruit first
    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        return 44.;
    } else {
        return [tableView minimumHeightForCellWithReuseIdentifier:reuseIdentifier atIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];

    if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return (_storySearchInProgressToken == nil);
        } else if (tableView == self.tableView) {
            return (_storyUpdateInProgressToken == nil);
        }
    } else {
        __block BOOL isExternalStory = NO;
        __block NSURL *externalURL = nil;
        MITNewsStory *story = [self tableView:tableView representedObjectForRowAtIndexPath:indexPath];

        [self.managedObjectContext performBlockAndWait:^{
            if ([story.type isEqualToString:MITNewsStoryExternalType]) {
                isExternalStory = YES;
                externalURL = story.sourceURL;
            }
        }];

        return (!isExternalStory || [[UIApplication sharedApplication] canOpenURL:externalURL]);
    }

    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];

    MITNewsStory *story = [self tableView:tableView representedObjectForRowAtIndexPath:indexPath];
    if (story) {
        __block BOOL isExternalStory = NO;
        __block NSURL *externalURL = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if ([story.type isEqualToString:MITNewsStoryExternalType]) {
                isExternalStory = YES;
                externalURL = story.sourceURL;
            }
        }];


        if (isExternalStory) {
            NSString *message = [NSString stringWithFormat:@"Open in Safari?"];
            UIAlertView *willOpenInExternalBrowserAlertView = [[UIAlertView alloc] initWithTitle:message message:[externalURL absoluteString] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
            [willOpenInExternalBrowserAlertView show];
        } else {
            [self performSegueWithIdentifier:@"showStoryDetail" sender:tableView];
        }
    } else {
        if ([reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier] && !_storyUpdateInProgressToken) {
            if (tableView == self.tableView) {
                __weak UITableView *weakTableView = self.tableView;
                [self loadStoriesInCategory:self.category
                         shouldLoadNextPage:YES
                                 completion:^(NSManagedObjectID *category, NSError *error) {
                                     UITableView *blockTableView = weakTableView;
                                     if (blockTableView) {
                                         [blockTableView reloadData];
                                     }
                                 }];
            } else if (tableView == self.searchDisplayController.searchResultsTableView && !_storySearchInProgressToken) {
                __weak UITableView *weakTableView = self.searchDisplayController.searchResultsTableView;
                [self loadStoriesForQuery:self.searchQuery
                                   loaded:^(NSString *query, NSError *error) {
                                       UITableView *blockTableView = weakTableView;
                                       if (blockTableView) {
                                           [blockTableView reloadData];
                                       }
                                   }];
            }

            [tableView reloadData];
        }

    }
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.tableView) {
        return (self.newsStories ? 1 : 0);
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? 1 : 0);
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        NSInteger numberOfRows = [self.newsStories count];

        if (numberOfRows > 0) {
            numberOfRows += 1; // Extra row for the 'Load More' cell
        }

        return numberOfRows;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if ([self.searchResults count]) {
            return [self.searchResults count] + 1;
        } else {
            return 0;
        }
    }

    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = [self tableView:tableView reuseIdentifierForRowAtIndexPath:indexPath];
    NSAssert(reuseIdentifier,@"[%@] missing UITableViewCell identifier in %@",self,NSStringFromSelector(_cmd));
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [self tableView:tableView configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        __block NSURL *url = nil;
        [self.managedObjectContext performBlockAndWait:^{
            MITNewsStory *story = [self selectedStory];
            if (story) {
                url = story.sourceURL;
            }
        }];

        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }

    UITableView *activeTableView = nil;
    if (self.isSearching) {
        activeTableView = self.searchDisplayController.searchResultsTableView;
    } else {
        activeTableView = self.tableView;
    }

    NSIndexPath *selectedIndexPath = [activeTableView indexPathForSelectedRow];
    [activeTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
}

#pragma mark UITableView Data Source Helpers
- (void)tableView:(UITableView*)tableView configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:MITNewsLoadMoreCellIdentifier]) {
        BOOL needsActivityIndicatorAccessory = NO;

        if (self.tableView == tableView) {
            cell.textLabel.enabled = !_storyUpdateInProgressToken;
            needsActivityIndicatorAccessory = (BOOL)_storyUpdateInProgressToken;
        } else if (self.searchDisplayController.searchResultsTableView == tableView) {
            cell.textLabel.enabled = !_storySearchInProgressToken;
            needsActivityIndicatorAccessory = (BOOL)_storySearchInProgressToken;
        }

        if (needsActivityIndicatorAccessory) {
            UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [view startAnimating];
            cell.accessoryView = view;
        } else {
            cell.accessoryView = nil;
        }
    } else {
        MITNewsStory *story = [self tableView:tableView representedObjectForRowAtIndexPath:indexPath];

        if ([cell isKindOfClass:[MITNewsStoryCell class]]) {
            MITNewsStoryCell *storyCell = (MITNewsStoryCell*)cell;
            
            if (story) {
                [self.managedObjectContext performBlockAndWait:^{
                    MITNewsStory *contextStory = (MITNewsStory*)[self.managedObjectContext existingObjectWithID:[story objectID] error:nil];
                    storyCell.story = contextStory;
                }];
            } else {
                storyCell.story = nil;
            }
        }
    }
}

- (NSString*)tableView:(UITableView*)tableView reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath
{
    MITNewsStory *newsStory = [self tableView:tableView representedObjectForRowAtIndexPath:indexPath];
    if (newsStory) {
        __block NSString *identifier = nil;
        [self.managedObjectContext performBlockAndWait:^{
            if ([newsStory.type isEqualToString:MITNewsStoryExternalType]) {
                if (newsStory.coverImage) {
                    identifier = MITNewsStoryExternalCellIdentifier;
                } else {
                    identifier = MITNewsStoryExternalNoImageCellIdentifier;
                }
            } else if ([newsStory.dek length])  {
                identifier = MITNewsStoryCellIdentifier;
            } else {
                identifier = MITNewsStoryNoDekCellIdentifier;
            }
        }];

        return identifier;
    } else {
        NSUInteger numberOfRowsInSection = [self tableView:tableView numberOfRowsInSection:indexPath.section];

        if ((indexPath.row) == (numberOfRowsInSection - 1)) {
            return MITNewsLoadMoreCellIdentifier;
        } else {
            return nil;
        }
    }
}

- (MITNewsStory*)tableView:(UITableView*)tableView representedObjectForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSInteger row = indexPath.row;
    
    if (tableView == self.tableView) {
        if (row < [self.newsStories count]) {
            return self.newsStories[row];
        } else {
            return nil;
        }
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        if (row < [self.searchResults count]) {
            return self.searchResults[row];
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}
@end


@implementation MITNewsCategoryViewController (NewsSearching)
- (void)beginSearchingAnimated:(BOOL)animated
{
    if (!self.isSearching) {
        _contentOffsetToRestoreAfterSearching = self.tableView.contentOffset;

        UISearchBar *searchBar = self.searchDisplayController.searchBar;
        searchBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 44.);
        [searchBar sizeToFit];
        self.tableView.tableHeaderView = searchBar;

        [UIView animateWithDuration:(animated ? 0.33 : 0)
                              delay:0.
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             [self.tableView scrollRectToVisible:searchBar.frame animated:NO];
                         } completion:^(BOOL finished) {
                             [searchBar becomeFirstResponder];
                             [self.navigationController setToolbarHidden:YES animated:NO];

                             self.searching = YES;
                         }];
    }
}


// Replace with a dedicated paging helper
- (void)loadStoriesForQuery:(NSString*)query loaded:(void (^)(NSString *query, NSError *error))completion
{
    // Default behavior is to automatically page the results (if the query matches the current
    //  one). If the two queries do not match, the search results will be cleared first.
    // Passing 'NO' for shouldLoadNextPage should always clear the results and reload the first
    //  page of stories.
    [self loadStoriesForQuery:query shouldLoadNextPage:YES completion:completion];
}

- (void)loadStoriesForQuery:(NSString*)query shouldLoadNextPage:(BOOL)loadNextPage completion:(void (^)(NSString *query, NSError *error))completion
{
    if (_storySearchInProgressToken) {
        DDLogWarn(@"there appears to be an request already in progress; it will be ignored upon completion");
    }

    NSUUID *requestUUID = [NSUUID UUID];
    self->_storySearchInProgressToken = requestUUID;

    if ([query length] == 0) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (requestUUID == _storySearchInProgressToken) {
                self.searchQuery = nil;
                self.searchResults = @[];

                [self willLoadSearchResultsAnimated:YES];

                if (completion) {
                    completion(query,nil);
                }

                [self didLoadResultsForSearchWithError:Nil animated:YES];

                _storySearchInProgressToken = nil;
            }
        }];
    } else {
        NSUInteger offset = 0;
        if (![self.searchQuery isEqualToString:query]) {
            self.searchResults = @[];
            offset = 0;
        } else if (loadNextPage) {
            offset = [self.searchResults count];
        }

        self.searchQuery = query;

        [self willLoadSearchResultsAnimated:YES];

        __weak MITNewsCategoryViewController *weakSelf = self;
        [[MITNewsModelController sharedController] storiesInCategory:nil query:query offset:offset limit:20 completion:^(NSArray *stories, NSDictionary* pagingMetadata, NSError *error) {
            MITNewsCategoryViewController *blockSelf = weakSelf;
            if (blockSelf) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    BOOL isSameRequestToken = (blockSelf->_storySearchInProgressToken == requestUUID);
                    if (isSameRequestToken) {
                        blockSelf->_storySearchInProgressToken = nil;

                        __block NSArray *localStories = nil;
                        [blockSelf.managedObjectContext performBlockAndWait:^{
                            localStories = [blockSelf.managedObjectContext transferManagedObjects:stories];
                        }];

                        // If we are loading the next (or additional pages, in general)
                        // we should append the results onto the existing search results.
                        // Otherwise, just do a wholesale replacement of the content.
                        if (loadNextPage) {
                            // Should have the same exact results as passing loadNextPage == NO,
                            //  if searchResults is currently nil or empty
                            NSMutableArray *newSearchResults = [NSMutableArray arrayWithArray:self.searchResults];
                            NSRange insertionRange = NSMakeRange(offset, [stories count]);
                            NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndexesInRange:insertionRange];

                            if (offset < [newSearchResults count]) {
                                [newSearchResults removeObjectsInRange:NSMakeRange(offset, [newSearchResults count])];
                            }

                            [newSearchResults insertObjects:stories atIndexes:insertedIndexes];
                            blockSelf.searchResults = newSearchResults;
                        } else {
                            blockSelf.searchResults = localStories;
                        }


                        [self didLoadResultsForSearchWithError:error animated:YES];

                        if (completion) {
                            if (error) {
                                completion(nil,error);
                            } else {
                                completion(query,nil);
                            }
                        }

                    }
                }];
            }
        }];
    }
}


- (void)willLoadSearchResultsAnimated:(BOOL)animate
{
    if (self.searchDisplayController.isActive) {
        UITableView *tableView = self.searchDisplayController.searchResultsTableView;

        if (![self.searchResults count]) {
            NSUInteger tag = 0xdeadbeef;
            MITLoadingActivityView *loadingActivityView = [[MITLoadingActivityView alloc] initWithFrame:tableView.bounds];
            loadingActivityView.tag = tag;
            [tableView addSubview:loadingActivityView];
        }
    }
}

- (void)didLoadResultsForSearchWithError:(NSError*)error animated:(BOOL)animate
{
    if (self.searchDisplayController.isActive) {
        UITableView *tableView = self.searchDisplayController.searchResultsTableView;

        NSUInteger tag = 0xdeadbeef;
        UIView *view = [tableView viewWithTag:tag];
        [view removeFromSuperview];
    }
}

- (void)endSearchingAnimated:(BOOL)animated
{
    if (self.isSearching) {
        UISearchBar *searchBar = self.searchDisplayController.searchBar;

        [UIView animateWithDuration:(animated ? 0.33 : 0)
                              delay:0.
                            options:UIViewAnimationCurveEaseIn
                         animations:^{
                             if (animated) {
                                 // Add in the search bar's height otherwise we will come up short
                                 CGPoint targetPoint = _contentOffsetToRestoreAfterSearching;
                                 targetPoint.y += CGRectGetHeight(searchBar.frame);
                                 [self.tableView setContentOffset:targetPoint animated:NO];
                             } else {
                                 [self.tableView setContentOffset:_contentOffsetToRestoreAfterSearching animated:NO];
                                 self.tableView.tableHeaderView = nil;
                             }

                             [self.navigationController setToolbarHidden:NO animated:NO];
                         } completion:^(BOOL finished) {
                             if (animated) {
                                 self.tableView.tableHeaderView = nil;

                                 // Now that the search bar is gone, correct out content offset to the
                                 // correct one.
                                 [self.tableView setContentOffset:_contentOffsetToRestoreAfterSearching animated:NO];
                             }
                             
                             self.searchQuery = nil;
                             self.searchResults = nil;
                             _contentOffsetToRestoreAfterSearching = CGPointZero;
                             self.searching = NO;
                         }];
    }
}


#pragma mark UISearchDisplayDelegate
- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalNoImageCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsStoryExternalNoImageCellIdentifier];
    [tableView registerNib:[UINib nibWithNibName:MITNewsLoadMoreCellNibName bundle:nil] forDynamicCellReuseIdentifier:MITNewsLoadMoreCellIdentifier];
}
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self loadStoriesForQuery:nil loaded:^(NSString *query, NSError *error) {
        [controller.searchResultsTableView reloadData];
    }];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    [self endSearchingAnimated:NO];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if ([searchString length] == 0) {
        [self loadStoriesForQuery:nil loaded:^(NSString *query, NSError *error) {
            [controller.searchResultsTableView reloadData];
        }];
        return YES;
    } else {
        return NO;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    NSString *searchQuery = searchBar.text;

    __weak UISearchDisplayController *searchDisplayController = self.searchDisplayController;
    [self loadStoriesForQuery:searchQuery loaded:^(NSString *query, NSError *error) {
        [searchDisplayController.searchResultsTableView reloadData];
    }];
}

@end
