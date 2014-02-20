#import "MITNewsStoriesViewController.h"
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

static NSString* const MITNewsStoryCellIdentifier = @"StoryCell";
static NSString* const MITNewsStoryCellNibName = @"NewsStoryTableCell";

static NSString* const MITNewsStoryNoDekCellIdentifier = @"StoryNoDekCell";
static NSString* const MITNewsStoryNoDekCellNibName = @"NewsStoryNoDekTableCell";

static NSString* const MITNewsStoryExternalType = @"news_clip";
static NSString* const MITNewsStoryExternalCellIdentifier = @"StoryExternalCell";
static NSString* const MITNewsStoryExternalCellNibName = @"NewsStoryExternalTableCell";

static NSUInteger MITNewsDefaultNumberOfStoriesPerPage = 20;

@interface MITNewsStoriesViewController () <NSFetchedResultsControllerDelegate,UISearchDisplayDelegate,UISearchBarDelegate>
@property (nonatomic) BOOL needsNavigationItemUpdate;
@property (nonatomic,getter = isUpdating) BOOL updating;
@property (nonatomic,getter = isSearching) BOOL searching;

@property (nonatomic,strong) NSMapTable *gestureRecognizersByView;
@property (nonatomic,strong) NSMapTable *categoriesByGestureRecognizer;
@property (nonatomic,strong) NSMapTable *sizingCellsByIdentifier;

@property (nonatomic,strong) NSString *searchQuery;

#pragma mark Table data sources
@property (nonatomic) NSUInteger numberOfStoriesPerPage;
@property (nonatomic,strong) NSArray *searchResults;
@property (nonatomic,strong) NSArray *newsStories;

@property (nonatomic,readonly) MITNewsStory *selectedStory;
@property (nonatomic,strong) MITNewsCategory *category;

- (UITableViewHeaderFooterView*)createLoadMoreFooterView;
@end

@implementation MITNewsStoriesViewController {
    NSManagedObjectID *_categoryObjectID;
    id _storyUpdateInProgressToken;
    id _storyUpdateForSearchQueryInProgressToken;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryNoDekCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryNoDekCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:MITNewsStoryExternalCellNibName bundle:nil] forCellReuseIdentifier:MITNewsStoryExternalCellIdentifier];

    if (self.numberOfStoriesPerPage == 0) {
        self.numberOfStoriesPerPage = MITNewsDefaultNumberOfStoriesPerPage;
    }
    
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
    [super viewWillAppear:animated];
    
    __block NSString *title = nil;
    [self.managedObjectContext performBlockAndWait:^{
        if (self.category) {
            title = self.category.name;
        } else {
            title = @"Top Stories";
        }
    }];
    
    self.title = title;

    if (!self.isSearching && !self.newsStories) {
        __weak MITNewsStoriesViewController *weakSelf = self;
        [self fetchFirstPageOfStoriesForCurrentCategory:^{
            MITNewsStoriesViewController *blockSelf = weakSelf;
            if (blockSelf) {
                if (blockSelf.newsStories && !blockSelf.tableView.tableFooterView) {
                    blockSelf.tableView.tableFooterView = [self createLoadMoreFooterView];
                } else if (!blockSelf.newsStories) {
                    blockSelf.tableView.tableFooterView = nil;
                }
                
                [self.tableView reloadData];
            }
        }];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateNavigationItemIfNeeded];
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
    } else {
        DDLogWarn(@"[%@] unknown segue '%@'",self,segue.identifier);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        __weak MITNewsStoriesViewController *weakSelf = self;
        [self fetchFirstPageOfStoriesForCurrentCategory:^{
            MITNewsStoriesViewController *blockSelf = weakSelf;
            if (blockSelf) {
                if (blockSelf.newsStories && !blockSelf.tableView.tableFooterView) {
                    blockSelf.tableView.tableFooterView = [blockSelf createLoadMoreFooterView];
                } else if (!blockSelf.newsStories) {
                    blockSelf.tableView.tableFooterView = nil;
                }
                
                [self.tableView reloadData];
            }
        }];
    }
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
    }
}

- (void)willBeginUpdating:(BOOL)animated
{
    [self setUpdateText:@"Updating..." animated:animated];
}

- (void)setUpdateText:(NSString*)string animated:(BOOL)animated
{
    UILabel *updatingLabel = [[UILabel alloc] init];
    updatingLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    updatingLabel.text = string;
    updatingLabel.backgroundColor = [UIColor clearColor];
    [updatingLabel sizeToFit];

    UIBarButtonItem *updatingItem = [[UIBarButtonItem alloc] initWithCustomView:updatingLabel];
    [self setToolbarItems:@[[UIBarButtonItem flexibleSpace],updatingItem,[UIBarButtonItem flexibleSpace]] animated:animated];
}

#pragma mark Navigation Item
- (void)setNeedsNavigationItemUpdate
{
    self.needsNavigationItemUpdate = YES;
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
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer*)sender;

        __weak UITableViewHeaderFooterView *footerView = (UITableViewHeaderFooterView*)gestureRecognizer.view;

        // Fall-out if the text label is current disabled
        if (!footerView.textLabel.isEnabled) {
            return;
        } else {
            footerView.textLabel.enabled = NO;
        }
            
        if (self.tableView.tableFooterView == footerView) {
            __weak UITableView *tableView = self.tableView;
            
            [self loadStoriesInCategory:self.category
                     shouldLoadNextPage:YES
                             completion:^(NSManagedObjectID *category, NSError *error) {
                                 footerView.textLabel.enabled = YES;
                                 [tableView reloadData];
                             }];
        } else if (self.searchDisplayController.searchResultsTableView.tableFooterView == footerView) {
            __weak UITableView *tableView = self.searchDisplayController.searchResultsTableView;
            [self loadStoriesForQuery:self.searchQuery
                   shouldLoadNextPage:YES
                           completion:^(NSString *query, NSError *error) {
                               footerView.textLabel.enabled = YES;
                               [tableView reloadData];
                           }];
        }
    }
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

- (void)fetchFirstPageOfStoriesForCurrentCategory:(void (^)(void))completion
{
    // nil out the update in progress token so that when the request returns
    // it skips its update (since we'll be messing with the data source)
    if (_storyUpdateInProgressToken) {
        _storyUpdateInProgressToken = nil;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
    
    if (_categoryObjectID) {
        MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:_categoryObjectID];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@",category];
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
            self.newsStories = results;        }
        
        if (objectCount == NSNotFound || objectCount < self.numberOfStoriesPerPage) {
            [self loadStoriesInCategory:self.category
                     shouldLoadNextPage:NO
                             completion:^(NSManagedObjectID *categoryID, NSError *error) {
                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                     if (completion) {
                                         completion();
                                     }
                                 }];
                             }];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (completion) {
                    completion();
                }
            }];
        }
    }];
}

- (void)loadStoriesInCategory:(MITNewsCategory*)category shouldLoadNextPage:(BOOL)shouldLoadNextPage completion:(void (^)(NSManagedObjectID *category,NSError *error))completion
{
    if (_storyUpdateInProgressToken) {
        DDLogWarn(@"there appears to be an request already in progress; it will be ignored");
    }
    
    __block NSString *categoryIdentifier = nil;
    [self.managedObjectContext performBlockAndWait:^{
        MITNewsCategory *category = (MITNewsCategory*)[self.managedObjectContext objectWithID:[self.category objectID]];
        categoryIdentifier = category.identifier;
    }];
    
    NSUUID *requestUUID = [NSUUID UUID];
    NSUInteger offset = 0;
    if (shouldLoadNextPage) {
        offset = [self.newsStories count];
    }
    
    __weak MITNewsStoriesViewController *weakSelf = self;
    void (^requestCompletionBlock)(NSArray*, MITResultsPager*, NSError*error) = ^(NSArray *stories, MITResultsPager *pager, NSError *error) {
        MITNewsStoriesViewController *blockSelf = weakSelf;
        if (blockSelf) {
            BOOL isSameRequestToken = (blockSelf->_storyUpdateInProgressToken == requestUUID);
            
            if (isSameRequestToken) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
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
                    
                    if (error) {
                        [self setUpdateText:@"Update failed" animated:NO];
                        
                        if (completion) {
                            completion(nil,error);
                        }
                    } else {
                        NSString *relativeDateString = [NSDateFormatter relativeDateStringFromDate:[NSDate date]
                                                                                            toDate:[NSDate date]];
                        NSString *updateText = [NSString stringWithFormat:@"Updated %@",relativeDateString];
                        [self setUpdateText:updateText animated:NO];
                        
                        if (completion) {
                            completion([category objectID],nil);
                        }
                    }
                }];
            }
        }
    };
    
    _storyUpdateInProgressToken = requestUUID;
    [[MITNewsModelController sharedController] storiesInCategory:categoryIdentifier
                                                           query:nil
                                                          offset:offset
                                                           limit:20
                                                      completion:requestCompletionBlock];

}

- (void)loadStoriesForQuery:(NSString*)query loaded:(void (^)(NSString *query, NSError *error))completion
{
    [self loadStoriesForQuery:query shouldLoadNextPage:NO completion:completion];
}

- (void)loadStoriesForQuery:(NSString*)query shouldLoadNextPage:(BOOL)loadNextPage completion:(void (^)(NSString *query, NSError *error))completion
{
    if (_storyUpdateForSearchQueryInProgressToken) {
        DDLogWarn(@"there appears to be an request already in progress; it will be ignored");
    }
    
    NSUUID *requestUUID = [NSUUID UUID];
    _storyUpdateForSearchQueryInProgressToken = [NSUUID UUID];
    
    if ([query length] == 0) {
        // Just 'cause I'm paranoid. This method *should* never be called
        // on any queue other than main.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (requestUUID == _storyUpdateForSearchQueryInProgressToken) {
                _storyUpdateForSearchQueryInProgressToken = nil;
                self.searchResults = @[];
            
                if (completion) {
                    completion(query,nil);
                }
            }
        }];
    } else {
        NSUInteger offset = 0;
        if (loadNextPage) {
            offset = [self.searchResults count];
        }
        
        __weak NSString *currentSearchQuery = self.searchQuery;
        __weak MITNewsStoriesViewController *weakSelf = self;
        void (^requestCompletionBlock)(NSArray*, MITResultsPager*, NSError*error) = ^(NSArray *stories, MITResultsPager *pager, NSError *error) {
            MITNewsStoriesViewController *blockSelf = weakSelf;
            if (blockSelf) {
                BOOL isSameQuery = (blockSelf.searchQuery == currentSearchQuery);
                BOOL isSameRequestToken = (blockSelf->_storyUpdateForSearchQueryInProgressToken == requestUUID);
                
                if (isSameQuery && isSameRequestToken) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        __block NSArray *localStories = nil;
                        [blockSelf.managedObjectContext performBlockAndWait:^{
                            localStories = [blockSelf.managedObjectContext transferManagedObjects:stories];
                        }];
                        
                        // If we are loading the next (or additional pages, in general)
                        // we should append the results onto the existing search results.
                        // Otherwise, just do a wholesale replacement of the content.
                        if (loadNextPage) {
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
                        
                        if (completion) {
                            if (error) {
                                completion(nil,error);
                            } else {
                                completion(query,nil);
                            }
                        }
                    }];
                }
            }
        };
        
        [[MITNewsModelController sharedController] storiesInCategory:nil
                                                               query:query
                                                              offset:offset
                                                               limit:20
                                                          completion:requestCompletionBlock];
    }
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
    NSUInteger row = (NSUInteger)indexPath.row;

    if (tableView == self.tableView) {
        return self.newsStories[row];
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

#pragma mark - UITableView
- (UITableViewHeaderFooterView*)createLoadMoreFooterView
{
    UITableViewHeaderFooterView* tableFooter = [[UITableViewHeaderFooterView alloc] init];
    tableFooter.frame = CGRectMake(0, 0, 320, 44);

    tableFooter.textLabel.textColor = [UIColor MITTintColor];
    tableFooter.textLabel.font = [UIFont boldSystemFontOfSize:16.];
    tableFooter.textLabel.text = @"Load more items...";

    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadMoreFooterTapped:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [tableFooter addGestureRecognizer:tapRecognizer];
    [tableFooter sizeToFit];

    return tableFooter;
}

#pragma mark UITableViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self respondsToSelector:@selector(setNeedsNavigationItemUpdate)]) {
        [self performSelector:@selector(setNeedsNavigationItemUpdate)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 22.;
    } else {
        return 0.;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
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
        return (self.newsStories ? 1 : 0);
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return (self.searchResults ? 1 : 0);
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return (self.newsStories ? [self.newsStories count] : 0);
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

        //storyCell.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleContent
        //                                                                      attributes:[MITNewsViewController titleTextAttributes]];
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

        //storyCell.dekLabel.attributedText = [[NSAttributedString alloc] initWithString:dekContent attributes:[MITNewsViewController dekTextAttributes]];
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
    
    __weak MITNewsStoriesViewController *weakSelf = self;
    [self loadStoriesForQuery:searchQuery
                       loaded:^(NSString *query, NSError *error) {
                           MITNewsStoriesViewController *blockSelf = weakSelf;
                           if (blockSelf) {
                               blockSelf.searchQuery = query;
                               
                               
                               if (!searchDisplayController.searchResultsTableView.tableFooterView) {
                                   searchDisplayController.searchResultsTableView.tableFooterView = [self createLoadMoreFooterView];
                               }
                               
                               [searchDisplayController.searchResultsTableView reloadData];
                           }
                       }];

}
@end
