#import "MIT_MobileAppDelegate.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "StoryThumbnailView.h"
#import "NewsStory.h"
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

#define SEARCH_BUTTON_TAG 7947
#define BOOKMARK_BUTTON_TAG 7948

@interface StoryListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, StoryDetailPagingDelegate, StoryXMLParserDelegate, MITScrollingNavigationBarDataSource, MITScrollingNavigationBarDelegate>
@property (nonatomic,weak) MITScrollingNavigationBar *navigationScroller;
@property (nonatomic,weak) UITableView *tableView;
@property (nonatomic,weak) UISearchBar *searchBar;

@property (strong) MITSearchDisplayController *searchController;
@property (strong) NSIndexPath *tempTableSelection;

@property (copy) NSArray *stories;
@property (copy) NSString *searchQuery;
@property (copy) NSArray *searchResults;
@property (copy) NSArray *categories;

@property (strong) StoryXMLParser *xmlParser;
@property NSInteger activeCategoryId;
@property NSInteger searchTotalAvailableResults;
@property BOOL showingBookmarks;
@property BOOL hasBookmarks;

@property (copy) NSArray *navigationButtons;

+ (NSArray*)orderedCategories;
+ (NSString*)titleForCategoryWithID:(NSNumber*)categoryID;

- (void)setStatusText:(NSString *)text;
- (void)setLastUpdated:(NSDate *)date;

- (void)showSearchBar;

- (void)pruneStories:(BOOL)asyncPrune;
@end

@implementation StoryListViewController

NSString *const NewsCategoryTopNews = @"Top News";
NSString *const NewsCategoryCampus = @"Campus";
NSString *const NewsCategoryEngineering = @"Engineering";
NSString *const NewsCategoryScience = @"Science";
NSString *const NewsCategoryManagement = @"Management";
NSString *const NewsCategoryArchitecture = @"Architecture";
NSString *const NewsCategoryHumanities = @"Humanities";

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

+ (NSString*)titleForCategoryWithID:(NSNumber*)categoryID
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

    return defaultCategories[categoryID];
}

- (void)loadView
{
    [super loadView];

    self.navigationItem.title = @"MIT News";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Headlines" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                                              target:self
                                                                                              action:@selector(showSearchBar)],
                                                [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                              target:nil
                                                                                              action:nil]];

    NSMutableArray *newCategories = [NSMutableArray array];
    NSManagedObjectContext *context = [[CoreDataManager coreDataManager] managedObjectContext];
    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"category_id = $CATEGORY_ID"];

    [[StoryListViewController orderedCategories] enumerateObjectsUsingBlock:^(NSString *categoryID, NSUInteger idx, BOOL *stop) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NewsCategoryEntityName];
        fetchRequest.predicate = [categoryPredicate predicateWithSubstitutionVariables:@{@"CATEGORY_ID" : @([categoryID integerValue])}];

        NSManagedObject *categoryObject = [[context executeFetchRequest:fetchRequest error:nil] lastObject];
        if (!categoryObject) {
            categoryObject = [NSEntityDescription insertNewObjectForEntityForName:NewsCategoryEntityName
                                                           inManagedObjectContext:context];
        }

        [categoryObject setValuesForKeysWithDictionary:@{@"category_id" : @([categoryID integerValue]),
                                                         @"expectedCount" : @(0)}];
        [newCategories addObject:categoryObject];
    }];
    
    self.categories = newCategories;

    [self pruneStories];
    // reduce number of saved stories to 10 when app quits
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pruneStories)
                                                 name:@"UIApplicationWillTerminateNotification"
                                               object:nil];


    MITScrollingNavigationBar *navigationBar = [[MITScrollingNavigationBar alloc] init];
    navigationBar.frame = CGRectMake(CGRectGetMinX(self.view.bounds),
                                     CGRectGetMinY(self.view.bounds),
                                     CGRectGetWidth(self.view.bounds),
                                     44.0);
    navigationBar.dataSource = self;
    navigationBar.delegate = self;
    navigationBar.backgroundColor = [UIColor colorWithWhite:0.95
                                                      alpha:1.0];
    self.navigationScroller = navigationBar;
    [self.view addSubview:navigationBar];


    // Story Table view
    CGRect tableFrame = self.view.bounds;
    tableFrame.origin.x = CGRectGetMinX(self.view.bounds);
    tableFrame.origin.y = CGRectGetMaxY(navigationBar.frame);
    tableFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(navigationBar.frame);

    UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [self.view addSubview:tableView];
    self.tableView = tableView;

    [tableView addPullToRefreshWithActionHandler:^{
        [self refresh:nil];
    }];

    [tableView.pullToRefreshView setTitle:@"Pull to refresh" forState:SVPullToRefreshStateStopped];
    [tableView.pullToRefreshView setTitle:@"Release to refresh" forState:SVPullToRefreshStateTriggered];
    [tableView.pullToRefreshView setTitle:@"Loading..." forState:SVPullToRefreshStateLoading];

    self.activeCategoryId = NSNotFound;
}

- (void)viewDidLoad
{
    [self loadFromCache];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // show / hide the bookmarks category
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NewsStoryEntityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    fetchRequest.resultType = NSCountResultType;
    
    NSManagedObjectContext *context = [[CoreDataManager coreDataManager] managedObjectContext];
    NSUInteger bookmarkCount = [context countForFetchRequest:fetchRequest
                                                       error:nil];
    self.hasBookmarks = (bookmarkCount != NSNotFound) && (bookmarkCount > 0);

    // Check to see if we were showing bookmarks from the last time
    // the view was visible
    if (self.showingBookmarks) {
        // Ensure we have the latest data available from CoreData
        [self loadFromCache];

        if (!self.hasBookmarks) {
            // If we no longer have any bookmarks available make sure reload the
            // available items in the navigation scroller and switch back to the Top News
            // category
            [self.navigationScroller reloadData];
            [self switchToCategory:NewsCategoryIdTopNews];
        }
    } else if (self.activeCategoryId == NSNotFound) {
        // First time appearing, make sure the Top news category is selected
        [self switchToCategory:NewsCategoryIdTopNews];
    }
    
    // Unselect the selected row
    self.tempTableSelection = [self.tableView indexPathForSelectedRow];
    if (self.tempTableSelection) {
        [self.tableView deselectRowAtIndexPath:self.tempTableSelection animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.tempTableSelection) {
        [self.tableView reloadRowsAtIndexPaths:@[self.tempTableSelection]
                              withRowAnimation:UITableViewRowAnimationNone];
        self.tempTableSelection = nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.navigationButtons = nil;
    self.searchQuery = nil;
    self.searchResults = nil;
    self.tempTableSelection = nil;
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
                    
                    BOOL shouldSave = storySaved = (([categoryStories count] < 10) &&
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
        
        [self loadFromCache];
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

#pragma mark - Search UI

- (void)showSearchBar
{
    if (!self.searchBar) {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:self.navigationScroller.frame];
        searchBar.tintColor = [UIColor colorWithRed:0.6
                                              green:0.2
                                               blue:0.2
                                              alpha:1.0];
        searchBar.backgroundColor = self.navigationScroller.backgroundColor;
        searchBar.alpha = 0.0;
        [self.view addSubview:searchBar];
        self.searchBar = searchBar;
    }

    if (!self.searchController) {
        self.searchController = [[MITSearchDisplayController alloc] initWithFrame:self.tableView.frame searchBar:self.searchBar contentsController:self];
        self.searchController.delegate = self;
        self.searchController.searchResultsDataSource = self;
        self.searchController.searchResultsDelegate = self;
    }

    [UIView animateWithDuration:0.4
                     animations:^{
                         [self.view bringSubviewToFront:self.searchBar];
                         self.searchBar.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [self.searchController setActive:YES
                                                     animated:YES];
                         }
                     }];
}

#pragma mark UISearchBar delegation

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // cancel any outstanding search
    if (self.xmlParser) {
        [self.xmlParser abort]; // cancel previous category's request if it's still going
        self.xmlParser = nil;
    }

    // hide search interface
    if (self.searchBar) {
        [UIView animateWithDuration:0.4
                         animations:^{
                             self.searchBar.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             [self.searchController.searchResultsTableView removeFromSuperview];
                             [self.searchBar removeFromSuperview];
                             self.searchResults = nil;
                             self.searchController = nil;
                         }];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchQuery = searchBar.text;
    [self loadSearchResultsFromServer:NO forQuery:self.searchQuery];

    if (![self.searchController.searchResultsTableView isDescendantOfView:self.view]) {
        [self.view addSubview:self.searchController.searchResultsTableView];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // when query is cleared, clear search result and show category instead
    if ([searchText length] == 0)
    {
        if ([self.searchResults count]) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        }

        self.searchResults = nil;
        [self loadFromCache];
    }
}

#pragma mark -
#pragma mark Story loading

// TODO break off all of the story loading and paging mechanics into a separate NewsDataManager
// Having all of the CoreData logic stuffed into here makes for ugly connections from story views back to this list view
// It also forces odd behavior of the paging controls when a memory warning occurs while looking at a story

- (void)switchToCategory:(NewsCategoryId)category
{
    NSAssert(category != 4, @"BOOM!");
    if (category != self.activeCategoryId) {
        if (self.xmlParser) {
            [self.xmlParser abort]; // cancel previous category's request if it's still going
            self.xmlParser = nil;
        }


        self.showingBookmarks = (category == BOOKMARK_BUTTON_TAG);
        if (self.showingBookmarks) {
            self.navigationScroller.selectedIndex = 0;
        } else {
            NSInteger categoryIndex = [[StoryListViewController orderedCategories] indexOfObject:@(category)];
            if (self.hasBookmarks) {
                // If we have bookmarks, the item at index 0 in the nav scroller will be the
                // Bookmarks category, so increment the index by 1 to match.
                ++categoryIndex;
            }

            if (categoryIndex != self.navigationScroller.selectedIndex) {
                self.navigationScroller.selectedIndex = categoryIndex;
            }
        }

        self.activeCategoryId = category;
        self.stories = nil;
        if ([self.stories count]) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        }

        [self.tableView reloadData];
        [self loadFromCache]; // makes request to server if no request has been made this session
    }
}

- (void)refresh:(id)sender
{
    if (!self.searchResults) {
        // get active category
        NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];

        // set its expectedCount to 0
        [aCategory setValue:@(0) forKey:@"expectedCount"];

        // reload
        [self loadFromCache];
    } else {
        [self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
    }
}


- (void)loadFromCache
{
    // if showing bookmarks, show those instead
    if (self.showingBookmarks) {
        [self setStatusText:@""];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
        self.stories = [[CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate] mutableCopy];
    } else {
        // load what's in CoreData, up to categoryCount
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"postDate" ascending:NO],
                                     //[NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"story_id" ascending:NO]];
        
        NSPredicate *predicate = nil;
        if (self.activeCategoryId == NewsCategoryIdTopNews) {
            predicate = [NSPredicate predicateWithFormat:@"(topStory != nil) && (topStory == YES)"];
        }
        else {
            predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id == %d", self.activeCategoryId];
        }

        // if maxLength == 0, nothing's been loaded from the server this session -- show up to 10 results from core data
        // else show up to maxLength
        NSMutableArray *results = [NSMutableArray arrayWithArray:[CoreDataManager objectsForEntity:NewsStoryEntityName
                                                                                 matchingPredicate:predicate
                                                                                   sortDescriptors:sortDescriptors]];
        if ([results count] && ([[results[0] featured] boolValue] == NO))
        {
            [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NewsStory *story = (NewsStory*)obj;
                
                if ([story.featured boolValue] == YES)
                {
                    [results exchangeObjectAtIndex:0
                                 withObjectAtIndex:idx];
                    (*stop) = YES;
                }
            }];
        }

        NSPredicate *categoryIdPredicate = [NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId];
        NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:categoryIdPredicate] lastObject];
        NSDate *lastUpdatedDate = [aCategory valueForKey:@"lastUpdated"];

        [self setLastUpdated:lastUpdatedDate];

        NSInteger maxLength = [[aCategory valueForKey:@"expectedCount"] integerValue];
        NSInteger resultsCount = [results count];
        if (maxLength == 0) {
            [self loadFromServer:NO]; // this creates a loop which will keep trying until there is at least something in this category
            // TODO: make sure this doesn't become an infinite loop.
            maxLength = 10;
        }

        if (maxLength > resultsCount) {
            maxLength = resultsCount;
        }
        self.stories = [results subarrayWithRange:NSMakeRange(0, maxLength)];
    }

    [self.tableView reloadData];
    [self.tableView flashScrollIndicators];
}

- (void)loadFromServer:(BOOL)loadMore
{
    // make an asynchronous call for more stories

    // start new request
    NewsStory *lastStory = [self.stories lastObject];
    NSInteger lastStoryId = (loadMore) ? [lastStory.story_id integerValue] : 0;
    if (self.xmlParser) {
        [self.xmlParser abort];
    }
    
    self.xmlParser = [[StoryXMLParser alloc] init];
    self.xmlParser.delegate = self;
    [self.xmlParser loadStoriesForCategory:self.activeCategoryId
                              afterStoryId:lastStoryId
                                     count:10]; // count doesn't do anything at the moment (no server support)
}

- (void)loadSearchResultsFromCache
{
    // make a predicate for everything with the search flag
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
    // show everything that comes back
    NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName
                                       matchingPredicate:[NSPredicate predicateWithFormat:@"searchResult == YES"]
                                         sortDescriptors:@[postDateSortDescriptor, storyIdSortDescriptor]];
    [self setStatusText:@""];
    if ([results count]) {
        self.searchResults = results;
        //self.stories = results;

        // hide translucent overlay
        [self.searchController hideSearchOverlayAnimated:YES];

        // show results
        [self.searchController.searchResultsTableView reloadData];
        [self.searchController.searchResultsTableView flashScrollIndicators];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"No matching articles found." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        self.searchResults = nil;
        [self.searchController.searchResultsTableView reloadData];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    DDLogVerbose(@"make sure search bar is first responder right now");
}

- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query
{
    if (self.xmlParser) {
        [self.xmlParser abort];
    }

    self.xmlParser = [[StoryXMLParser alloc] init];
    self.xmlParser.delegate = self;

    [self.xmlParser loadStoriesforQuery:query
                             afterIndex:((loadMore) ? [self.searchResults count] : 0)
                                  count:10];
}

#pragma mark -
#pragma mark StoryXMLParser delegation
- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error
{
    if (parser == self.xmlParser) {
        // TODO: communicate download failure to user
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            DDLogError(@"News download failed because there's no net connection");
        } else {
            DDLogError(@"Download failed for parser %@ with error %@", parser, [error userInfo]);
        }

        [self.tableView.pullToRefreshView setTitle:@"Update failed"
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
        [self.tableView.pullToRefreshView stopAnimating];

        if ([self.stories count]) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0]
                                          animated:YES];
        }
    }
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser) {
        // basic category request
        if (!parser.isSearch) {
            NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];
            NSInteger length = [[aCategory valueForKey:@"expectedCount"] integerValue];
            if (length == 0) { // fresh load of category, set its updated date
                [aCategory setValue:[NSDate date] forKey:@"lastUpdated"];
            }

            length += [self.xmlParser.addedStories count];
            [aCategory setValue:@(length) forKey:@"expectedCount"];
            if (!parser.loadingMore && [self.stories count]) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:NO];
            }

            self.xmlParser = nil;
            
            if (parser.loadingMore == NO) {
                [self pruneStories:NO];
            }
            
            [self loadFromCache];
        } else {
            self.searchTotalAvailableResults = self.xmlParser.totalAvailableResults;
            [self loadSearchResultsFromCache];

            if (!parser.loadingMore && [self.searchResults count]) {
                [self.searchController.searchResultsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                                                    atScrollPosition:UITableViewScrollPositionTop
                                                                            animated:NO];
            }

            self.xmlParser = nil;
        }

        [self.tableView.pullToRefreshView stopAnimating];
    }
}

#pragma mark -
#pragma mark Bottom status bar

- (void)setStatusText:(NSString *)text
{
    [self.tableView.pullToRefreshView setTitle:text
                                      forState:SVPullToRefreshStateAll];
    [self.tableView.pullToRefreshView setSubtitle:@""
                                         forState:SVPullToRefreshStateAll];
}

- (void)setLastUpdated:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [self setStatusText:(date) ? [NSString stringWithFormat:@"Updated %@", [formatter stringFromDate:date]] : nil];
}

#pragma mark -
#pragma mark UIViewController

- (BOOL)shouldAutorotate {
    return NO;
}


#pragma mark -
#pragma mark UITableViewDataSource and UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    if (tableView == self.tableView) {
        numberOfRows = [self.stories count];
        if (!self.showingBookmarks && numberOfRows < 200 && numberOfRows > 0) {
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
        return [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d found", self.searchTotalAvailableResults]];
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
                    NSInteger remainingArticlesToLoad = (!self.searchResults) ? (200 - [dataSource count]) : (self.searchTotalAvailableResults - [dataSource count]);
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

#pragma mark -
#pragma mark Browsing hooks
- (BOOL)storyDetailView:(StoryDetailViewController*)storyDetailController canSelectPreviousStory:(NewsStory*)currentStory
{
    NSArray *storyDataSource = self.searchResults;
    if (!self.searchResults) {
        // The searchResults array should be nil unless are in searching mode
        // so it should be safe to use as a guard
        // @see searchBarCancelButtonClicked:
        storyDataSource = self.stories;
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
    // searchController should only be non-nil if we are currently searching
    // TODO: replace this with an isSearching boolean
    if (self.searchController) {
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
    NSArray *storyDataSource = self.searchResults;
    if (!self.searchResults) {
        storyDataSource = self.stories;
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
    if (self.searchController) {
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

#pragma mark - MITScrollingNavigationBarDataSource
- (NSUInteger)numberOfItemsInNavigationBar:(MITScrollingNavigationBar*)navigationBar
{
    NSUInteger count = [[StoryListViewController orderedCategories] count];
    if (self.hasBookmarks) {
        ++count;
    }

    return count;
}

- (NSString*)navigationBar:(MITScrollingNavigationBar*)navigationBar titleForItemAtIndex:(NSInteger)index
{
    if (self.hasBookmarks) {
        if (index == 0) {
            return @"Bookmarks";
        } else {
            --index;
        }
    }

    NSArray *categories = [StoryListViewController orderedCategories];
    return [StoryListViewController titleForCategoryWithID:categories[index]];
}

#pragma mark - MITScrollingNavigationBarDelegate
- (void)navigationBar:(MITScrollingNavigationBar *)navigationBar didSelectItemAtIndex:(NSInteger)index
{
    if (self.hasBookmarks) {
        if (index == 0) {
            [self switchToCategory:BOOKMARK_BUTTON_TAG];
            return;
        } else {
            --index;
        }
    }

    NSArray *categoryIds = [StoryListViewController orderedCategories];
    [self switchToCategory:[categoryIds[index] integerValue]];
}

- (CGFloat)widthForAccessoryViewInNavigationBar:(MITScrollingNavigationBar *)navigationBar
{
    return 0.;
}

- (UIView*)accessoryViewForNavigationBar:(MITScrollingNavigationBar *)navigationBar
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"global/search"]
            forState:UIControlStateNormal];
    button.showsTouchWhenHighlighted = YES;

    [button addTarget:self
               action:@selector(showSearchBar)
     forControlEvents:UIControlEventTouchUpInside];

    return button;
}

@end
