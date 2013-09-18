#import "MIT_MobileAppDelegate.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "StoryThumbnailView.h"
#import "NewsStory.h"
#import "NewsCategory.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"
#import "MITScrollingNavigationBar.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "UIImageView+WebCache.h"

#define SCROLL_TAB_HORIZONTAL_PADDING 5.0
#define SCROLL_TAB_HORIZONTAL_MARGIN  5.0

#define THUMBNAIL_WIDTH 76.0
#define ACCESSORY_WIDTH_PLUS_PADDING 18.0
#define STORY_TEXT_PADDING_TOP 3.0 // with 15pt titles, makes for 8px of actual whitespace
#define STORY_TEXT_PADDING_BOTTOM 7.0 // from baseline of 12pt font, is roughly 5px
#define STORY_TEXT_PADDING_LEFT 7.0
#define STORY_TEXT_PADDING_RIGHT 7.0
#define STORY_TEXT_WIDTH (320.0 - STORY_TEXT_PADDING_LEFT - STORY_TEXT_PADDING_RIGHT - THUMBNAIL_WIDTH - ACCESSORY_WIDTH_PLUS_PADDING) // 8px horizontal padding
#define STORY_TEXT_HEIGHT (THUMBNAIL_WIDTH - STORY_TEXT_PADDING_TOP - STORY_TEXT_PADDING_BOTTOM) // 8px vertical padding (bottom is less because descenders on dekLabel go below baseline)
#define STORY_TITLE_FONT_SIZE 15.0
#define STORY_DEK_FONT_SIZE 12.0

static NSUInteger const MITNewsStoryFetchBatchSize = 10;
static NSTimeInterval const MITNewsStoryDefaultAnimationDuration = 0.5;

static NSString *const NewsCategoryTopNews = @"Top News";
static NSString *const NewsCategoryCampus = @"Campus";
static NSString *const NewsCategoryEngineering = @"Engineering";
static NSString *const NewsCategoryScience = @"Science";
static NSString *const NewsCategoryManagement = @"Management";
static NSString *const NewsCategoryArchitecture = @"Architecture";
static NSString *const NewsCategoryHumanities = @"Humanities";

@interface StoryListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate,
                                        UISearchBarDelegate, StoryDetailPagingDelegate, StoryXMLParserDelegate,
                                        MITScrollingNavigationBarDataSource, MITScrollingNavigationBarDelegate>
@property (nonatomic,weak) MITScrollingNavigationBar *navigationScroller;
@property (nonatomic,weak) UITableView *tableView;
@property (nonatomic,weak) UISearchBar *searchBar;
@property (nonatomic,strong) MITSearchDisplayController *searchController;


@property (copy) NSArray *stories;
@property (copy) NSString *searchQuery;
@property (copy) NSArray *searchResults;
@property (copy) NSArray *categories;

@property (strong) StoryXMLParser *xmlParser;
@property (getter=isLoadingMoreStories) BOOL loadingMoreStories;

@property NSInteger activeCategoryId;
@property NSInteger searchTotalAvailableResults;

+ (NSArray*)orderedCategories;
+ (NSString*)titleForCategoryWithID:(NewsCategoryId)categoryID;

- (BOOL)hasBookmarks;
- (void)setStatusTitle:(NSString*)title subtitle:(NSString*)subtitle;
- (void)setLastUpdated:(NSDate *)date asSubtitle:(BOOL)asSubtitle;

- (void)pruneStories DEPRECATED_ATTRIBUTE;
- (void)pruneStories:(BOOL)asyncPrune DEPRECATED_ATTRIBUTE;

- (void)loadFromServer:(BOOL)loadMore;
- (void)loadSearchResultsFromCache;
- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query;


/* Bookmark handling */
- (IBAction)showBookmarks:(id)sender;
- (IBAction)hideBookmarks:(id)sender;
- (void)showBookmarksAnimated:(BOOL)animated;
- (void)hideBookmarksAnimated:(BOOL)animated;
@end

@implementation StoryListViewController
+ (NSArray*)orderedCategories
{
    return @[@(NewsCategoryIdTopNews),
             @(NewsCategoryIdCampus),
             @(NewsCategoryIdEngineering),
             @(NewsCategoryIdScience),
             @(NewsCategoryIdManagement),
             @(NewsCategoryIdArchitecture),
             @(NewsCategoryIdHumanities)];
}

+ (NSString*)titleForCategoryWithID:(NewsCategoryId)categoryID
{
    static NSDictionary *defaultCategories = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultCategories = @{@(NewsCategoryIdTopNews) : NewsCategoryTopNews,
                              @(NewsCategoryIdCampus) : NewsCategoryCampus,
                              @(NewsCategoryIdEngineering) : NewsCategoryEngineering,
                              @(NewsCategoryIdScience) : NewsCategoryScience,
                              @(NewsCategoryIdManagement) : NewsCategoryManagement,
                              @(NewsCategoryIdArchitecture) : NewsCategoryArchitecture,
                              @(NewsCategoryIdHumanities) : NewsCategoryHumanities};
    });
    
    return defaultCategories[@(categoryID)];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    view.layer.masksToBounds = YES;
    self.view = view;
    
    self.navigationItem.title = @"MIT News";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Headlines" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    CGRect channelNavigationFrame = CGRectMake(CGRectGetMinX(self.view.bounds),
                                               CGRectGetMinY(self.view.bounds),
                                               CGRectGetWidth(self.view.bounds),
                                               44.0);
    MITScrollingNavigationBar *navigationBar = [[MITScrollingNavigationBar alloc] initWithFrame:channelNavigationFrame];
    navigationBar.dataSource = self;
    navigationBar.delegate = self;

    navigationBar.autoresizingMask = UIViewAutoresizingNone;
    navigationBar.backgroundColor = [UIColor colorWithWhite:0.95
                                                      alpha:1.0];
    navigationBar.layer.shadowOpacity = 1.0;
    self.navigationScroller = navigationBar;
    [self.view addSubview:navigationBar];
    
    
    // Story Table view
    CGRect tableFrame = self.view.bounds;
    tableFrame.origin.x = CGRectGetMinX(self.view.bounds);
    tableFrame.origin.y = CGRectGetMaxY(navigationBar.frame);
    tableFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(navigationBar.frame);
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    tableView.frame = tableFrame;
    tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                  UIViewAutoresizingFlexibleHeight |
                                  UIViewAutoresizingFlexibleTopMargin);
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [tableView addPullToRefreshWithActionHandler:^{
        [self refresh:nil];
    }];
    
    [tableView.pullToRefreshView setTitle:@"Pull to refresh" forState:SVPullToRefreshStateStopped];
    [tableView.pullToRefreshView setTitle:@"Release to refresh" forState:SVPullToRefreshStateTriggered];
    [tableView.pullToRefreshView setTitle:@"Loading..." forState:SVPullToRefreshStateLoading];
    
    [self.view insertSubview:tableView
                belowSubview:self.navigationScroller];
    self.tableView = tableView;
    
}

- (void)viewDidLoad
{
    self.activeCategoryId = NewsCategoryIdInvalid;
    
    NSManagedObjectContext *context = [[CoreDataManager coreDataManager] managedObjectContext];
    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"category_id = $CATEGORY_ID"];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NewsCategoryEntityName];
    NSArray *categoriesFetchResults = [context executeFetchRequest:fetchRequest
                                                             error:nil];
    NSMutableOrderedSet *categories = [NSMutableOrderedSet orderedSetWithArray:categoriesFetchResults];
    
    [[StoryListViewController orderedCategories] enumerateObjectsUsingBlock:^(NSString *categoryID, NSUInteger idx, BOOL *stop) {
        NSPredicate *predicate = [categoryPredicate predicateWithSubstitutionVariables:@{@"CATEGORY_ID" : @([categoryID integerValue])}];
        
        NewsCategory *category = [[categories filteredOrderedSetUsingPredicate:predicate] lastObject];
        if (!category) {
            category = [NSEntityDescription insertNewObjectForEntityForName:NewsCategoryEntityName
                                                     inManagedObjectContext:context];
        }
        
        category.category_id = @([categoryID integerValue]);
        [categories addObject:category];
    }];
    
    NSArray *orderedCategoryIDs = [StoryListViewController orderedCategories];
    [categories sortUsingComparator:^NSComparisonResult(NewsCategory *category1, NewsCategory *category2) {
        NSUInteger index1 = [orderedCategoryIDs indexOfObject:category1.category_id];
        NSUInteger index2 = [orderedCategoryIDs indexOfObject:category2.category_id];
        
        return [@(index1) compare:@(index2)];
    }];
    
    self.categories = [categories array];
    [self.navigationScroller reloadData];
    
    [self pruneStories];
    // reduce number of saved stories to 10 when app quits
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pruneStories)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationItemBarButtonsAnimated:animated];
    
    if (self.activeCategoryId == NewsCategoryIdInvalid) {
        // First time appearing, make sure the Top news category is selected
        [self switchToCategory:NewsCategoryIdTopNews];
    }
    
    
    // The selection is left alone when the StoryDetailViewController
    // is pushed onto the stack because, due to the pagingDelegate,
    // the currently selected story may change and we want to give the user
    // a hint that they aren't where they started
    UITableView *tableView = nil;
    if (self.isSearching) {
        tableView = self.searchController.searchResultsTableView;
    } else {
        tableView = self.tableView;
    }
    
    [tableView beginUpdates];
    {
        NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
        [tableView deselectRowAtIndexPath:selectedIndexPath
                                 animated:animated];
        
        if ([[tableView indexPathsForVisibleRows] containsObject:selectedIndexPath]) {
            [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows]
                             withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    [tableView endUpdates];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.isSearching) {
        [self loadFromCacheAnimated:animated];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self.xmlParser abort];
    self.xmlParser = nil;
    
    self.searchQuery = nil;
    self.searchResults = nil;
    self.stories = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return MITCanAutorotateForOrientation(interfaceOrientation, [self supportedInterfaceOrientations]);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
}

- (void)pruneStories
{
    [self pruneStories:YES];
}

- (void)pruneStories:(BOOL)asyncPrune
{
    dispatch_block_t pruningBlock = ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        NSPredicate *notBookmarkedPredicate = [NSPredicate predicateWithFormat:@"(bookmarked == nil) || (bookmarked == NO)"];
        
        {
            NSEntityDescription *newsStoryEntity = [NSEntityDescription entityForName:NewsStoryEntityName
                                                               inManagedObjectContext:context];
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            fetchRequest.entity = newsStoryEntity;
            fetchRequest.predicate = notBookmarkedPredicate;
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"postDate" ascending:NO]];
            
            NSArray *stories = [context executeFetchRequest:fetchRequest
                                                      error:NULL];
            
            NSMutableDictionary *savedArticles = [NSMutableDictionary dictionary];
            for (NewsStory *story in stories)
            {
                BOOL storySaved = NO;
                
                for (NSManagedObject *category in story.categories)
                {
                    NSNumber *categoryID = [category valueForKey:@"category_id"];
                    NSMutableSet *categoryStories = savedArticles[categoryID];
                    
                    if (categoryStories == nil)
                    {
                        categoryStories = [NSMutableSet set];
                        savedArticles[categoryID] = categoryStories;
                    }
                    
                    BOOL shouldSave = storySaved = (([categoryStories count] < MITNewsStoryFetchBatchSize) &&
                                                    (story.postDate != nil) &&
                                                    ([story.postDate compare:[NSDate date]] != NSOrderedDescending));
                    if (shouldSave) {
                        [categoryStories addObject:story];
                    }
                }
                
                if (storySaved == NO) {
                    [context deleteObject:story];
                }
            }
            
            [savedArticles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                DDLogVerbose(@"Category %@ has %d articles after pruning", key, [obj count]);
            }];
        }
        
        NSError *error = nil;
        [context save:&error];
        
        if (error) {
            DDLogError(@"[News] Failed to save pruning context: %@", [error localizedDescription]);
        }
        
        [self loadFromCacheAnimated:NO];
    };
    
    
    // (bskinner,6/6/2013)
    // TODO: Fix news to support asynchronous operation a bit better
    //  At the moment, news is *very* unhappy if things are happening
    // asynchronously on the main thread. Rework News to use a
    // NSFetchedResultsController for managing it's data and bump
    // the data updates either to a general data controller or at least
    // NSOperation-sized chunks.
    dispatch_async(dispatch_get_main_queue(), pruningBlock);
}

#pragma mark - Navigation Bar Updating
- (void)updateNavigationItemBarButtonsAnimated:(BOOL)animated
{
    if (!self.isSearching) {
        if (self.isShowingBookmarks) {
            // If we are currently showing the bookmarks, the navigation item should only have a 'Done' item available
            UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                      target:self
                                                                                      action:@selector(hideBookmarks:)];
            [self.navigationItem setRightBarButtonItems:@[doneItem] animated:animated];
        } else {
            // If we are not searching and not showing bookmarks, use the default navigation item config
            // for this controller (a search icon with an optional bookmarks icon)
            NSMutableArray *items = [[NSMutableArray alloc] init];
            if ([self hasBookmarks]) {
                UIBarButtonItem *bookmarksButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                                     target:self
                                                                                                     action:@selector(showBookmarks:)];
                [items addObject:bookmarksButtonItem];
            }

            UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                        target:self
                                                                                        action:@selector(showSearchBar:)];
            [items addObject:searchItem];

            [self.navigationItem setRightBarButtonItems:items
                                               animated:animated];
        }
    } else {
        // If we are searching, don't display anything. The user needs to press the 'cancel' button in order
        // to get out of search mode
        [self.navigationItem setRightBarButtonItems:nil animated:animated];
    }
}

#pragma mark - Bookmark UI
- (BOOL)hasBookmarks
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NewsStoryEntityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    fetchRequest.resultType = NSCountResultType;
    
    NSManagedObjectContext *context = [[CoreDataManager coreDataManager] managedObjectContext];
    NSError *error = nil;
    NSUInteger bookmarkCount = [context countForFetchRequest:fetchRequest
                                                       error:&error];
    
    if (error) {
        DDLogWarn(@"failed to fetch News bookmarks: %@",error);
    }
    
    return (!error && (bookmarkCount > 0));
}

- (IBAction)showBookmarks:(id)sender
{
    [self showBookmarksAnimated:YES];
}

- (IBAction)hideBookmarks:(id)sender
{
    [self hideBookmarksAnimated:YES];
}


- (void)setShowingBookmarks:(BOOL)showingBookmarks
{
    [self setShowingBookmarks:showingBookmarks animated:YES];
}

- (void)setShowingBookmarks:(BOOL)showingBookmarks animated:(BOOL)animated
{
    if (self.isSearching) {
        return;
    } else if (_showingBookmarks != showingBookmarks) {
        _showingBookmarks = showingBookmarks;

        if (_showingBookmarks) {
            [self showBookmarksAnimated:animated];
        } else {
            [self hideBookmarksAnimated:animated];
        }
    }
}

- (void)showBookmarksAnimated:(BOOL)animated
{
    if (!(self.isSearching || self.isShowingBookmarks)) {
        [self updateNavigationItemBarButtonsAnimated:YES];
        [UIView animateWithDuration:(animated ? MITNewsStoryDefaultAnimationDuration : 0)
                              delay:0
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                             CGRect frame = self.navigationScroller.frame;
                             frame.origin.y = CGRectGetMinY(self.view.bounds) - CGRectGetHeight(frame);
                             self.navigationScroller.frame = frame;
                             self.tableView.frame = self.view.bounds;
                         }
                         completion:^(BOOL finished) {
                             [self loadFromCacheAnimated:NO];
                         }];
    }
}

- (void)hideBookmarksAnimated:(BOOL)animated
{
    if (self.isShowingBookmarks) {
        [self updateNavigationItemBarButtonsAnimated:YES];
        [UIView animateWithDuration:(animated ? MITNewsStoryDefaultAnimationDuration : 0)
                         animations:^{
                             CGRect frame = self.navigationScroller.frame;
                             frame.origin.y = CGRectGetMinY(self.view.bounds);
                             self.navigationScroller.frame = frame;

                             CGRect tableFrame = self.tableView.frame;
                             tableFrame.origin.y = CGRectGetMaxY(frame);
                             self.tableView.frame = tableFrame;

                             [self loadFromCacheAnimated:animated];
                         } completion:nil];
    }
}

#pragma mark - Search UI
- (IBAction)showSearchBar:(id)sender;
{
    [self showSearchAnimated:YES];
}

- (void)showSearchAnimated:(BOOL)animated
{
    if (!self.isSearching) {
        self.searching = YES;

        if (!self.searchBar) {
            CGRect searchBarFrame = self.navigationScroller.frame;
            searchBarFrame.origin.x = CGRectGetMaxX(self.view.frame) + CGRectGetWidth(searchBarFrame);

            UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:searchBarFrame];
            searchBar.tintColor = [UIColor colorWithRed:0.6
                                                  green:0.2
                                                   blue:0.2
                                                  alpha:1.0];
            searchBar.backgroundColor = self.navigationScroller.backgroundColor;
            searchBar.alpha = 1.;
            [self.view addSubview:searchBar];
            self.searchBar = searchBar;
        }

        if (!self.searchController) {
            MITSearchDisplayController *searchController = [[MITSearchDisplayController alloc] initWithFrame:self.tableView.frame
                                                                                                   searchBar:self.searchBar
                                                                                          contentsController:self];
            searchController.searchResultsDataSource = self;
            searchController.searchResultsDelegate = self;
            searchController.delegate = self;
            self.searchController = searchController;
        }

        [self updateNavigationItemBarButtonsAnimated:animated];
        [UIView animateWithDuration:(animated ? MITNewsStoryDefaultAnimationDuration : 0.)
                         animations:^{
                             self.searchBar.frame = self.navigationScroller.frame;
                         }
                         completion:^(BOOL finished) {
                             [self.searchController setActive:YES
                                                     animated:NO];
                         }];
    }
}

- (void)hideSearchAnimated:(BOOL)animated
{
    if (self.isSearching) {
        self.searching = NO;

        [self updateNavigationItemBarButtonsAnimated:animated];

        [UIView animateWithDuration:(animated ? MITNewsStoryDefaultAnimationDuration : 0.)
                         animations:^{
                             CGRect searchBarFrame = self.searchBar.frame;
                             searchBarFrame.origin.x = CGRectGetMaxX(self.view.frame) + CGRectGetWidth(searchBarFrame);
                             self.searchBar.frame = searchBarFrame;
                         }
                         completion:^(BOOL finished) {
                             [self.searchBar removeFromSuperview];
                             [self.searchController setActive:NO
                                                     animated:animated];
                             self.searchController = nil;
                             self.searchResults = nil;
                         }];
    }
}

#pragma mark - Story loading

// TODO break off all of the story loading and paging mechanics into a separate NewsDataManager
// Having all of the CoreData logic stuffed into here makes for ugly connections from story views back to this list view
// It also forces odd behavior of the paging controls when a memory warning occurs while looking at a story
- (void)switchToCategory:(NewsCategoryId)categoryId
{
    if (categoryId != self.activeCategoryId) {
        if (self.xmlParser) {
            [self.xmlParser abort]; // cancel previous category's request if it's still going
            self.xmlParser = nil;
        }
        
        [self.categories enumerateObjectsUsingBlock:^(NewsCategory *category, NSUInteger idx, BOOL *stop) {
            if ([category.category_id isEqualToNumber:@(categoryId)]) {
                if (idx != self.navigationScroller.selectedIndex) {
                    self.navigationScroller.selectedIndex = idx;
                }

                CGPoint offset = self.tableView.contentOffset;
                offset.y = 0.;
                self.tableView.contentOffset = offset;
                self.activeCategoryId = categoryId;
                [self loadFromServer:NO];
                (*stop) = YES;
            }
        }];
    }
}

- (void)refresh:(id)sender
{
    // The search controller should be nil unless we are
    // currently in the middle of a search
    if (!self.isSearching) {
        [self loadFromServer:NO];
    } else {
        [self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
    }
}

- (void)loadFromCacheAnimated:(BOOL)animated
{
    NSArray *oldStories = self.stories;
    
    // if showing bookmarks, show those instead
    if (self.isShowingBookmarks) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
        self.stories = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
    } else {
        // load what's in CoreData, up to categoryCount
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"postDate" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"story_id" ascending:NO]];
        
        NSPredicate *predicate = nil;
        if (self.activeCategoryId == NewsCategoryIdTopNews) {
            predicate = [NSPredicate predicateWithFormat:@"(topStory != nil) && (topStory == YES)"];
        } else {
            predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id == %d", self.activeCategoryId];
        }
        
        NSMutableArray *results = [NSMutableArray arrayWithArray:[CoreDataManager objectsForEntity:NewsStoryEntityName
                                                                                 matchingPredicate:predicate
                                                                                   sortDescriptors:sortDescriptors]];
        __block NSUInteger newZerothStoryIndex = NSNotFound;
        [results enumerateObjectsUsingBlock:^(NewsStory *story, NSUInteger idx, BOOL *stop) {
            BOOL featured = [story featured];
            
            if (idx == 0 && featured) {
                (*stop) = YES;
            } else if (featured) {
                newZerothStoryIndex = idx;
                (*stop) = YES;
            }
        }];
        
        if (newZerothStoryIndex != NSNotFound) {
            NewsStory *featuredStory = results[newZerothStoryIndex];
            [results removeObjectAtIndex:newZerothStoryIndex];
            [results insertObject:featuredStory atIndex:0];
        }
        
        if (!self.stories) {
            // If the stories is currently nil, then this is the first time
            // that we are loading this view controller. Use this as a hint to
            // refresh the current articles from the server
            [self loadFromServer:NO];
        }
        
        self.stories = results;
    }
    
    if (![self.stories isEqualToArray:oldStories]) {
        [self.tableView reloadData];
    }
}

- (void)loadFromServer:(BOOL)loadingMoreStories
{
    // start new request
    NewsStory *lastStory = [self.stories lastObject];
    
    // If we are loading more stories, we'll need the id of the last story we have
    // cached locally. Otherwise, use '0' as the field is ignored.
    NSInteger lastStoryId = (loadingMoreStories) ? [lastStory.story_id integerValue] : 0;
    if (self.xmlParser) {
        [self.xmlParser abort];
    }
    
    self.loadingMoreStories = loadingMoreStories;
    self.xmlParser = [[StoryXMLParser alloc] init];
    self.xmlParser.delegate = self;
    [self.xmlParser loadStoriesForCategory:self.activeCategoryId
                              afterStoryId:lastStoryId
                                     count:MITNewsStoryFetchBatchSize]; // count doesn't do anything at the moment (no server support)
}

- (void)loadSearchResultsFromCache
{
    [self loadSearchResultsFromCacheAnimated:YES];
}

- (void)loadSearchResultsFromCacheAnimated:(BOOL)animated
{
    // make a predicate for everything with the search flag
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
    
    // show everything that comes back
    NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName
                                       matchingPredicate:[NSPredicate predicateWithFormat:@"searchResult == YES"]
                                         sortDescriptors:@[postDateSortDescriptor, storyIdSortDescriptor]];
    [self setStatusTitle:nil
                subtitle:nil];
    self.searchResults = results;
    
    UITableView *tableView = self.searchController.searchResultsTableView;
    if ([tableView numberOfSections]) {
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                 withRowAnimation:(animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone)];
    } else {
        [tableView reloadData];
    }
}

- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query
{
    if (self.xmlParser) {
        [self.xmlParser abort];
    }
    
    self.xmlParser = [[StoryXMLParser alloc] init];
    self.xmlParser.delegate = self;
    self.loadingMoreStories = loadMore;
    
    [self.xmlParser loadStoriesforQuery:query
                             afterIndex:((loadMore) ? [self.searchResults count] : 0)
                                  count:10];
}

#pragma mark - Delegate Methods
#pragma mark StoryXMLParserDelegate
- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error
{
    if (parser == self.xmlParser) {
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            DDLogError(@"News download failed because there's no net connection");
        } else {
            DDLogError(@"Download failed for parser %@ with error %@", parser, [error userInfo]);
        }
        
        [self.tableView.pullToRefreshView setTitle:@"Update failed"
                                          forState:SVPullToRefreshStateAll];
        [self.tableView.pullToRefreshView setSubtitle:[error localizedDescription]
                                             forState:SVPullToRefreshStateAll];
        [self.tableView.pullToRefreshView stopAnimating];
        
        [UIAlertView alertViewForError:error withTitle:@"News" alertViewDelegate:nil];
        if ([self.stories count]) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error
{
    if (parser == self.xmlParser) {
        [self.tableView.pullToRefreshView setTitle:@"Update failed"
                                          forState:SVPullToRefreshStateAll];
        [self.tableView.pullToRefreshView setSubtitle:[error localizedDescription]
                                             forState:SVPullToRefreshStateAll];
        [self.tableView.pullToRefreshView stopAnimating];
    }
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser) {
        BOOL isLoadingMoreStories = self.isLoadingMoreStories;
        
        if (!self.isSearching) {
            // Looks like a search is not active, this is just a regular category request.
            
            NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId];
            NewsCategory *category = [[self.categories filteredArrayUsingPredicate:categoryPredicate] lastObject];
            if (!isLoadingMoreStories) {
                category.lastUpdated = [NSDate date];
                [self setLastUpdated:category.lastUpdated asSubtitle:NO];
            }
            
            [self loadFromCacheAnimated:YES];
        } else {
            self.searchTotalAvailableResults = self.xmlParser.totalAvailableResults;
            
            if (!isLoadingMoreStories && [self.searchResults count]) {
                [self.searchController.searchResultsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                                    atScrollPosition:UITableViewScrollPositionTop
                                                                            animated:NO];
            }
            
            [self loadSearchResultsFromCacheAnimated:NO];
        }
        
        self.loadingMoreStories = NO;
        self.xmlParser = nil;
        [self.tableView.pullToRefreshView stopAnimating];
    }
}

#pragma mark -
#pragma mark Bottom status bar

- (void)setStatusTitle:(NSString *)title subtitle:(NSString*)subtitle
{
    [self.tableView.pullToRefreshView setTitle:title
                                      forState:SVPullToRefreshStateAll];
}

- (void)setLastUpdated:(NSDate *)date asSubtitle:(BOOL)asSubtitle
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    NSString *dateString = nil;
    if (date) {
        dateString = [NSString stringWithFormat:@"Updated %@", [formatter stringFromDate:date]];
    }
    
    if (asSubtitle) {
        [self.tableView.pullToRefreshView setSubtitle:dateString
                                             forState:SVPullToRefreshStateAll];
    } else {
        [self.tableView.pullToRefreshView setTitle:dateString
                                          forState:SVPullToRefreshStateAll];
    }
}

#pragma mark -
#pragma mark UIViewController

- (BOOL)shouldAutorotate {
    return NO;
}


#pragma mark - UITableViewDataSource and UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (tableView == self.tableView) {
        numberOfRows = [self.stories count];
        if (!self.isShowingBookmarks && numberOfRows < 200 && numberOfRows > 0) {
            // The MIT API server only returns up to, at most, 200 stories.
            // If there are less than 200 stories cached (but there are more than 0),
            // increment the count so the 'Load more articles' row will be added
            ++numberOfRows;
        }
    } else if (tableView == self.searchController.searchResultsTableView) {
        numberOfRows = [self.searchResults count];
        if (numberOfRows < self.searchTotalAvailableResults && numberOfRows > 0) {
            // We aren't displaying all of the available search results yet.
            // Add the extra row to show the 'Load more articles'
            ++numberOfRows;
        }
    }
    
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchController.searchResultsTableView) {
        // Only the search table has a section header
        return UNGROUPED_SECTION_HEADER_HEIGHT;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchController.searchResultsTableView) {
        NSString *headerText = nil;
        if (!self.isSearching) {
            headerText = @"Loading...";
        } else {
            headerText = [NSString stringWithFormat:@"%d found", self.searchTotalAvailableResults];
        }
        
        return [UITableView ungroupedSectionHeaderWithTitle:headerText];
    }
    
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *dataSource = nil;
    if (tableView == self.tableView) {
        dataSource = self.stories;
    } else if (tableView == self.searchController.searchResultsTableView) {
        dataSource = self.searchResults;
    }
    
    if (indexPath.row == [dataSource count]) {
        // Height of the 'Load more articles' row
        return 50.;
    } else {
        return THUMBNAIL_WIDTH;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *StoryCellReuseIdentifier = @"StoryCellReuseIdentifier";
    static NSString *MoreArticlesReuseIdentifier = @"MoreArticlesReuseIdentifier";
    
    NSArray *dataSource = nil;
    if (tableView == self.tableView) {
        dataSource = self.stories;
    } else if (tableView == self.searchController.searchResultsTableView) {
        dataSource = self.searchResults;
    }
    
    UITableViewCell *cell = nil;
    
    // Both tables use the same exact cell structure so we don't need to check
    // to see which table view is asking us for data here.
    switch (indexPath.section)
    {
        case 0:
        {
            if (indexPath.row < [dataSource count]) {
                NewsStory *story = dataSource[indexPath.row];
                
                cell = [tableView dequeueReusableCellWithIdentifier:StoryCellReuseIdentifier];
                
                UILabel *titleLabel = nil;
                UILabel *dekLabel = nil;
                UIImageView *thumbnailView = nil;
                
                if (cell == nil) {
                    // Set up the cell
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:StoryCellReuseIdentifier];
                    
                    // Title View
                    titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    titleLabel.tag = 1;
                    titleLabel.font = [UIFont boldSystemFontOfSize:STORY_TITLE_FONT_SIZE];
                    titleLabel.numberOfLines = 0;
                    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    [cell.contentView addSubview:titleLabel];
                    
                    // Summary View
                    dekLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    dekLabel.tag = 2;
                    dekLabel.font = [UIFont systemFontOfSize:STORY_DEK_FONT_SIZE];
                    dekLabel.textColor = [UIColor colorWithHexString:@"#0D0D0D"];
                    dekLabel.highlightedTextColor = [UIColor whiteColor];
                    dekLabel.numberOfLines = 0;
                    dekLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    [cell.contentView addSubview:dekLabel];
                    
                    thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH)];
                    thumbnailView.tag = 3;
                    [cell.contentView addSubview:thumbnailView];
                    
                    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                }
                
                titleLabel = (UILabel *)[cell viewWithTag:1];
                dekLabel = (UILabel *)[cell viewWithTag:2];
                thumbnailView = (UIImageView *)[cell viewWithTag:3];
                
                titleLabel.text = story.title;
                dekLabel.text = story.summary;
                
                titleLabel.textColor = ([story.read boolValue]) ? [UIColor colorWithHexString:@"#666666"] : [UIColor blackColor];
                titleLabel.highlightedTextColor = [UIColor whiteColor];
                
                // Calculate height
                CGFloat availableHeight = STORY_TEXT_HEIGHT;
                CGSize titleDimensions = [titleLabel.text sizeWithFont:titleLabel.font
                                                     constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight)
                                                         lineBreakMode:NSLineBreakByTruncatingTail];
                availableHeight -= titleDimensions.height;
                
                CGSize dekDimensions = CGSizeZero;
                // if not even one line will fit, don't show the deck at all
                if (availableHeight > dekLabel.font.leading) {
                    dekDimensions = [dekLabel.text sizeWithFont:dekLabel.font
                                              constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight)
                                                  lineBreakMode:NSLineBreakByTruncatingTail];
                }
                
                
                titleLabel.frame = CGRectMake(THUMBNAIL_WIDTH + STORY_TEXT_PADDING_LEFT,
                                              STORY_TEXT_PADDING_TOP,
                                              STORY_TEXT_WIDTH,
                                              titleDimensions.height);
                dekLabel.frame = CGRectMake(THUMBNAIL_WIDTH + STORY_TEXT_PADDING_LEFT,
                                            ceil(CGRectGetMaxY(titleLabel.frame)),
                                            STORY_TEXT_WIDTH,
                                            dekDimensions.height);
                
                NSURL *imageURL = [NSURL URLWithString:story.inlineImage.thumbImage.url];
                [thumbnailView setImageWithURL:imageURL
                              placeholderImage:[UIImage imageNamed:@"news/news-placeholder"]];
            } else if (indexPath.row == [dataSource count]) {
                cell = [tableView dequeueReusableCellWithIdentifier:MoreArticlesReuseIdentifier];
                
                if (cell == nil) {
                    // Set up the cell
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MoreArticlesReuseIdentifier];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    
                    UILabel *moreArticlesLabel = [[UILabel alloc] initWithFrame:cell.frame];
                    moreArticlesLabel.font = [UIFont boldSystemFontOfSize:16];
                    moreArticlesLabel.numberOfLines = 1;
                    moreArticlesLabel.textColor = [UIColor colorWithHexString:@"#990000"];
                    moreArticlesLabel.text = @"Load 10 more articles..."; // just something to make it place correctly
                    [moreArticlesLabel sizeToFit];
                    moreArticlesLabel.tag = 1234;
                    CGRect frame = moreArticlesLabel.frame;
                    frame.origin.x = 10;
                    frame.origin.y = ((NSInteger)(50.0 - moreArticlesLabel.frame.size.height)) / 2;
                    moreArticlesLabel.frame = frame;
                    
                    [cell.contentView addSubview:moreArticlesLabel];
                }
                
                UILabel *moreArticlesLabel = (UILabel *)[cell viewWithTag:1234];
                if (moreArticlesLabel) {
                    NSInteger remainingArticlesToLoad = (!self.isSearching) ? (200 - [dataSource count]) : (self.searchTotalAvailableResults - [dataSource count]);
                    moreArticlesLabel.text = [NSString stringWithFormat:@"Load %d more articles...", (remainingArticlesToLoad > 10) ? 10 : remainingArticlesToLoad];
                    if (!self.xmlParser)
                    { // disable when a load is already in progress
                        moreArticlesLabel.textColor = [UIColor colorWithHexString:@"#990000"]; // enable
                    }
                    else
                    {
                        moreArticlesLabel.textColor = [UIColor colorWithHexString:@"#999999"]; // disable
                    }
                    
                    
                    [moreArticlesLabel sizeToFit];
                }
            } else {
                DDLogError(@"%@ attempted to show non-existent row (%d) with actual count of %d", NSStringFromSelector(_cmd), indexPath.row, [dataSource count]);
            }
        }
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isSearchResults;
    NSArray *dataSource = nil;
    if (tableView == self.tableView) {
        dataSource = self.stories;
        isSearchResults = NO;
    } else if (tableView == self.searchController.searchResultsTableView) {
        dataSource = self.searchResults;
        isSearchResults = YES;
    }
    
    
    if (indexPath.row == [dataSource count]) {
        if (!self.xmlParser) { // only "load x more..." if no other load is going on
            if (isSearchResults) {
                [self loadSearchResultsFromServer:YES forQuery:self.searchQuery];
            } else {
                [self loadFromServer:YES];
            }
        }
    } else {
        StoryDetailViewController *detailViewController = [[StoryDetailViewController alloc] init];
        detailViewController.pagingDelegate = self;
        detailViewController.story = dataSource[indexPath.row];
        
        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}

#pragma mark StoryDetailPagingDelegate
- (BOOL)storyDetailView:(StoryDetailViewController*)storyDetailController canSelectPreviousStory:(NewsStory*)currentStory
{
    NSArray *storyDataSource = self.stories;
    if (self.isSearching) {
        storyDataSource = self.searchResults;
    }
    
    NSUInteger storyIndex = [storyDataSource indexOfObject:currentStory];
    if (storyIndex != NSNotFound) {
        return (storyIndex > 0);
    } else {
        return false;
    }
}

- (NewsStory*)storyDetailView:(StoryDetailViewController*)storyDetailController selectPreviousStory:(NewsStory*)currentStory
{
    if (self.isSearching) {
        NSUInteger storyIndex = [self.searchResults indexOfObject:currentStory];
        
        if ((storyIndex != NSNotFound) && (storyIndex > 0)) {
            --storyIndex;
            
            NSIndexPath *storyIndexPath = [NSIndexPath indexPathForRow:storyIndex inSection:0];
            [self.searchController.searchResultsTableView selectRowAtIndexPath:storyIndexPath
                                                                      animated:NO
                                                                scrollPosition:UITableViewScrollPositionMiddle];
            return self.searchResults[storyIndex];
        }
    } else {
        NSUInteger storyIndex = [self.stories indexOfObject:currentStory];
        
        if ((storyIndex != NSNotFound) && (storyIndex > 0)) {
            --storyIndex;
            
            NSIndexPath *storyIndexPath = [NSIndexPath indexPathForRow:storyIndex inSection:0];
            [self.tableView selectRowAtIndexPath:storyIndexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionMiddle];
            return self.stories[storyIndex];
        }
    }
    
    return nil;
}

- (BOOL)storyDetailView:(StoryDetailViewController*)storyDetailController canSelectNextStory:(NewsStory*)currentStory
{
    NSArray *storyDataSource = self.stories;
    if (self.isSearching) {
        storyDataSource = self.searchResults;
    }
    
    NSUInteger storyIndex = [storyDataSource indexOfObject:currentStory];
    if (storyIndex != NSNotFound) {
        return (storyIndex < [storyDataSource count]);
    } else {
        return false;
    }
}

- (NewsStory*)storyDetailView:(StoryDetailViewController*)storyDetailController selectNextStory:(NewsStory*)currentStory
{
    // searchController should only be non-nil if we are currently searching
    // TODO: replace this with an isSearching boolean
    if (self.isSearching) {
        NSUInteger storyIndex = [self.searchResults indexOfObject:currentStory];
        
        if ((storyIndex != NSNotFound) && (storyIndex < [self.searchResults count])) {
            ++storyIndex;
            
            NSIndexPath *storyIndexPath = [NSIndexPath indexPathForRow:storyIndex inSection:0];
            [self.searchController.searchResultsTableView selectRowAtIndexPath:storyIndexPath
                                                                      animated:NO
                                                                scrollPosition:UITableViewScrollPositionMiddle];
            return self.searchResults[storyIndex];
        }
    } else {
        NSUInteger storyIndex = [self.stories indexOfObject:currentStory];
        
        if ((storyIndex != NSNotFound) && (storyIndex < [self.stories count])) {
            ++storyIndex;
            
            NSIndexPath *storyIndexPath = [NSIndexPath indexPathForRow:storyIndex inSection:0];
            [self.tableView selectRowAtIndexPath:storyIndexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionMiddle];
            return self.stories[storyIndex];
        }
    }
    
    return nil;
}

#pragma mark MITScrollingNavigationBarDataSource
- (NSUInteger)numberOfItemsInNavigationBar:(MITScrollingNavigationBar*)navigationBar
{
    return [self.categories count];
}

- (NSString*)navigationBar:(MITScrollingNavigationBar*)navigationBar titleForItemAtIndex:(NSInteger)index
{
    NSNumber *categoryID = [self.categories[index] valueForKey:@"category_id"];
    return [StoryListViewController titleForCategoryWithID:(NewsCategoryId)[categoryID integerValue]];
}

#pragma mark MITScrollingNavigationBarDelegate
- (void)navigationBar:(MITScrollingNavigationBar *)navigationBar didSelectItemAtIndex:(NSInteger)index
{
    NSNumber *categoryID = [self.categories[index] valueForKey:@"category_id"];
    [self switchToCategory:(NewsCategoryId)[categoryID integerValue]];
}

#pragma mark UISearchBar delegation
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    [self hideSearchAnimated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (![self.searchQuery isEqualToString:searchBar.text]) {
        self.searchResults = nil;
        [self.searchController.searchResultsTableView reloadData];
    }
    
    self.searchQuery = searchBar.text;
    [self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
    
    // TODO: Get this out of here! It belongs in the MITSearchDisplayController implementation
    if (self.searchController.searchResultsTableView.superview != self.view) {
        self.searchController.searchResultsTableView.alpha = 0.;
        self.searchController.searchResultsTableView.frame = self.tableView.frame;
        [self.view addSubview:self.searchController.searchResultsTableView];
        
        [UIView animateWithDuration:0.4
                         animations:^{
                             self.searchController.searchResultsTableView.alpha = 1.;
                         } completion:^(BOOL finished) {
                             
                         }];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    if ([searchBar.text length] == 0) {
        [self.searchController.searchResultsTableView removeFromSuperview];
    }
}

@end
