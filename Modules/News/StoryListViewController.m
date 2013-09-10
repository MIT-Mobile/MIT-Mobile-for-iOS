#import "MIT_MobileAppDelegate.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "StoryThumbnailView.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "MITUIConstants.h"

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

@interface StoryListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, StoryXMLParserDelegate, NavScrollerDelegate>
@property (nonatomic,weak) NavScrollerView *navigationScroller;
@property (nonatomic,weak) UITableView *tableView;
@property (nonatomic,weak) UISearchBar *searchBar;
@property (nonatomic,weak) UIView *activityView;

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

- (void)setupNavScroller;
- (void)setupNavScrollButtons;
- (void)buttonPressed:(id)sender;

- (void)setupActivityIndicator;
- (void)setStatusText:(NSString *)text;
- (void)setLastUpdated:(NSDate *)date;
- (void)setProgress:(CGFloat)value;

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];


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

    // Story Table view
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)viewDidLoad
{
    [self setupNavScroller];

    CGRect tableFrame = CGRectMake(CGRectGetMinX(self.view.bounds),
                                   CGRectGetHeight(self.navigationScroller.frame),
                                   CGRectGetWidth(self.view.bounds),
                                   CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.navigationScroller.frame));
    self.tableView.frame = tableFrame;

    [self setupActivityIndicator];

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
    
    [self setupNavScrollButtons];
    if (self.showingBookmarks) {
        [self loadFromCache];
        if (!self.hasBookmarks) {
            [self buttonPressed:self.navigationButtons[0]];
        }
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
                                                    name:@"UIApplicationWillTerminateNotification"
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


#pragma mark - Category selector
- (void)setupNavScroller
{
    if (!self.navigationScroller) {
        // Nav Scroller View
        NavScrollerView *navigationScroller = [[NavScrollerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
        navigationScroller.navScrollerDelegate = self;
        [self.view addSubview:navigationScroller];
        self.navigationScroller = navigationScroller;
    }
}

- (void)setupNavScrollButtons
{
    [self.navigationScroller removeAllButtons];

    // add search button

    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
    [searchButton setImage:searchImage forState:UIControlStateNormal];
    searchButton.adjustsImageWhenHighlighted = NO;
    searchButton.tag = SEARCH_BUTTON_TAG; // random number that won't conflict with news categories

    [self.navigationScroller addButton:searchButton shouldHighlight:NO];

    if (self.hasBookmarks) {
        UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *bookmarkImage = [UIImage imageNamed:MITImageNameBookmark];
        [bookmarkButton setImage:bookmarkImage forState:UIControlStateNormal];
        bookmarkButton.adjustsImageWhenHighlighted = NO;
        bookmarkButton.tag = BOOKMARK_BUTTON_TAG; // random number that won't conflict with news categories
        [self.navigationScroller addButton:bookmarkButton shouldHighlight:NO];
    }
    // add pile of text buttons

    // create buttons for nav scroller view
    [[StoryListViewController orderedCategories] enumerateObjectsUsingBlock:^(NSNumber *categoryID, NSUInteger idx, BOOL *stop) {
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [aButton setTitle:[StoryListViewController titleForCategoryWithID:categoryID]
                 forState:UIControlStateNormal];
        [self.navigationScroller addButton:aButton shouldHighlight:YES];
    }];


    UIButton *homeButton = [self.navigationScroller buttonWithTag:self.activeCategoryId];
    [self.navigationScroller buttonPressed:homeButton];
}

- (void)buttonPressed:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;
    if (pressedButton.tag == SEARCH_BUTTON_TAG)
    {
        [self showSearchBar];
    }
    else
    {
        [self switchToCategory:pressedButton.tag];
    }
}

#pragma mark -
#pragma mark Search UI

- (void)showSearchBar
{
    if (!self.searchBar) {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        searchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        searchBar.alpha = 0.0;
        [self.view addSubview:searchBar];
        self.searchBar = searchBar;
    }

    if (!self.searchController) {
        CGRect frame = CGRectMake(0.0,
                                  CGRectGetHeight(self.searchBar.frame),
                                  CGRectGetWidth(self.view.bounds),
                                  CGRectGetHeight(self.view.bounds) - (CGRectGetHeight(self.searchBar.frame) + CGRectGetHeight(self.activityView.bounds)));
        self.searchController = [[MITSearchDisplayController alloc] initWithFrame:frame searchBar:self.searchBar contentsController:self];
        self.searchController.delegate = self;
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
    if (self.xmlParser)
    {
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
                             [self.searchBar removeFromSuperview];
                         }];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //[self unfocusSearchBar];

    self.searchQuery = searchBar.text;
    [self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
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
#pragma mark News activity indicator

- (void)setupActivityIndicator
{
    UIView *activityView = [[UIView alloc] initWithFrame:CGRectZero];
    activityView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    activityView.tag = 9;
    activityView.backgroundColor = [UIColor blackColor];
    activityView.userInteractionEnabled = NO;

    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 0, 0)];
    loadingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    loadingLabel.tag = 10;
    loadingLabel.text = @"Loading...";
    loadingLabel.textColor = [UIColor colorWithHexString:@"#DDDDDD"];
    loadingLabel.font = [UIFont boldSystemFontOfSize:14.0];
    loadingLabel.backgroundColor = [UIColor blackColor];
    loadingLabel.opaque = YES;
    [activityView addSubview:loadingLabel];
    loadingLabel.hidden = YES;

    CGSize labelSize = [loadingLabel.text sizeWithFont:loadingLabel.font forWidth:self.view.bounds.size.width lineBreakMode:NSLineBreakByTruncatingTail];

    [self.view addSubview:activityView];

    CGFloat bottom = CGRectGetMaxY(self.tableView.frame);
    CGFloat height = labelSize.height + 8;
    activityView.frame = CGRectMake(0, bottom - height, self.view.bounds.size.width, height);

    UIProgressView *progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    progressBar.tag = 11;
    progressBar.frame = CGRectMake((8 + (NSInteger)labelSize.width) + 5, 0, activityView.frame.size.width - (8 + (NSInteger)labelSize.width) - 13, progressBar.frame.size.height);
    progressBar.center = CGPointMake(progressBar.center.x, (NSInteger)(activityView.frame.size.height / 2) + 1);
    [activityView addSubview:progressBar];
    progressBar.progress = 0.0;
    progressBar.hidden = YES;

    UILabel *updatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, activityView.frame.size.width - 16, activityView.frame.size.height)];
    updatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    updatedLabel.tag = 12;
    updatedLabel.text = @"";
    updatedLabel.textColor = [UIColor colorWithHexString:@"#DDDDDD"];
    updatedLabel.font = [UIFont boldSystemFontOfSize:14.0];
    updatedLabel.textAlignment = NSTextAlignmentRight;
    updatedLabel.backgroundColor = [UIColor blackColor];
    updatedLabel.opaque = YES;
    [activityView addSubview:updatedLabel];

    // shrink table down to accomodate
    CGRect frame = self.tableView.frame;
    frame.size.height = frame.size.height - height;
    self.tableView.frame = frame;
    self.activityView = activityView;
}

#pragma mark -
#pragma mark Story loading

// TODO break off all of the story loading and paging mechanics into a separate NewsDataManager
// Having all of the CoreData logic stuffed into here makes for ugly connections from story views back to this list view
// It also forces odd behavior of the paging controls when a memory warning occurs while looking at a story

- (void)switchToCategory:(NewsCategoryId)category
{
    if (category != self.activeCategoryId) {
        if (self.xmlParser) {
            [self.xmlParser abort]; // cancel previous category's request if it's still going
            self.xmlParser = nil;
        }

        self.activeCategoryId = category;
        self.stories = nil;
        if ([self.stories count]) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        }

        [self.tableView reloadData];

        self.showingBookmarks = (category == BOOKMARK_BUTTON_TAG);
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
        self.stories = results;

        // hide translucent overlay
        [self.searchController hideSearchOverlayAnimated:YES];

        // show results
        [self.tableView reloadData];
        [self.tableView flashScrollIndicators];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"No matching articles found." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        self.searchResults = nil;
        self.stories = nil;
        [self.tableView reloadData];
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

- (void)parserDidStartDownloading:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser) {
        [self setProgress:0.1];
        [self.tableView reloadData];
    }
}

- (void)parserDidStartParsing:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser) {
        [self setProgress:0.3];
    }
}

- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone
{
    if (parser == self.xmlParser) {
        [self setProgress:0.3 + 0.7 * percentDone * 0.01];
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error
{
    if (parser == self.xmlParser) {
        // TODO: communicate download failure to user
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            DDLogError(@"News download failed because there's no net connection");
        } else {
            DDLogError(@"Download failed for parser %@ with error %@", parser, [error userInfo]);
        }

        [self setStatusText:@"Update failed"];

        [UIAlertView alertViewForError:error withTitle:@"News" alertViewDelegate:nil];
        if ([self.stories count]) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error
{
    if (parser == self.xmlParser) {
        // TODO: communicate parse failure to user
        [self setStatusText:@"Update failed"];
		[UIAlertView alertViewForError:error withTitle:@"News" alertViewDelegate:nil];
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
            if (!parser.loadingMore && [self.stories count])
            {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionTop
                                              animated:NO];
            }

            self.xmlParser = nil;
            [self loadSearchResultsFromCache];
        }
    }
}

#pragma mark -
#pragma mark Bottom status bar

- (void)setStatusText:(NSString *)text
{
    UILabel *loadingLabel = (UILabel *)[self.activityView viewWithTag:10];
    UIProgressView *progressBar = (UIProgressView *)[self.activityView viewWithTag:11];
    UILabel *updatedLabel = (UILabel *)[self.activityView viewWithTag:12];
    loadingLabel.hidden = YES;
    progressBar.hidden = YES;
    updatedLabel.hidden = NO;
    updatedLabel.text = text;
}

- (void)setLastUpdated:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [self setStatusText:(date) ? [NSString stringWithFormat:@"Last updated %@", [formatter stringFromDate:date]] : nil];
}

- (void)setProgress:(CGFloat)value
{
    UILabel *loadingLabel = (UILabel *)[self.activityView viewWithTag:10];
    UIProgressView *progressBar = (UIProgressView *)[self.activityView viewWithTag:11];
    UILabel *updatedLabel = (UILabel *)[self.activityView viewWithTag:12];
    loadingLabel.hidden = NO;
    progressBar.hidden = NO;
    updatedLabel.hidden = YES;
    progressBar.progress = value;
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
    return (self.stories.count > 0) ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger n = 0;
    switch (section)
    {
        case 0:
            n = self.stories.count;
            // don't show "load x more" row if
            if (!self.showingBookmarks && // showing bookmarks
                !(self.searchResults && n >= self.searchTotalAvailableResults) && // showing all search results
                !(!self.searchResults && n >= 200))
            { // showing all of a category
                n += 1; // + 1 for the "Load more articles..." row
            }
            break;
    }
    return n;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 && self.searchResults)
    {
        return UNGROUPED_SECTION_HEADER_HEIGHT;
    }
    else
    {
        return 0.0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *titleView = nil;

    if (section == 0 && self.searchResults)
    {
        titleView = [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d found", self.searchTotalAvailableResults]];
    }

    return titleView;

}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = THUMBNAIL_WIDTH;

    switch (indexPath.section)
    {
        case 0:
        {
            if (indexPath.row < self.stories.count)
            {
                rowHeight = THUMBNAIL_WIDTH;
            }
            else
            {
                rowHeight = 50; // "Load more articles..."
            }

            break;
        }
    }
    return rowHeight;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *result = nil;

    switch (indexPath.section)
    {
        case 0:
        {
            if (indexPath.row < self.stories.count)
            {
                NewsStory *story = self.stories[indexPath.row];

                static NSString *StoryCellIdentifier = @"StoryCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StoryCellIdentifier];

                UILabel *titleLabel = nil;
                UILabel *dekLabel = nil;
                StoryThumbnailView *thumbnailView = nil;

                if (cell == nil)
                {
                    // Set up the cell
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:StoryCellIdentifier];

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

                    thumbnailView = [[StoryThumbnailView alloc] initWithFrame:CGRectMake(0, 0, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH)];
                    thumbnailView.tag = 3;
                    [cell.contentView addSubview:thumbnailView];
                    
                    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                }

                titleLabel = (UILabel *)[cell viewWithTag:1];
                dekLabel = (UILabel *)[cell viewWithTag:2];
                thumbnailView = (StoryThumbnailView *)[cell viewWithTag:3];

                titleLabel.text = story.title;
                dekLabel.text = story.summary;

                titleLabel.textColor = ([story.read boolValue]) ? [UIColor colorWithHexString:@"#666666"] : [UIColor blackColor];
                titleLabel.highlightedTextColor = [UIColor whiteColor];

                // Calculate height
                CGFloat availableHeight = STORY_TEXT_HEIGHT;
                CGSize titleDimensions = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:NSLineBreakByTruncatingTail];
                availableHeight -= titleDimensions.height;

                CGSize dekDimensions = CGSizeZero;
                // if not even one line will fit, don't show the deck at all
                if (availableHeight > dekLabel.font.leading)
                {
                    dekDimensions = [dekLabel.text sizeWithFont:dekLabel.font constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:NSLineBreakByTruncatingTail];
                }


                titleLabel.frame = CGRectMake(THUMBNAIL_WIDTH + STORY_TEXT_PADDING_LEFT,
                        STORY_TEXT_PADDING_TOP,
                        STORY_TEXT_WIDTH,
                                                              titleDimensions.height);
                dekLabel.frame = CGRectMake(THUMBNAIL_WIDTH + STORY_TEXT_PADDING_LEFT,
                                                            ceil(CGRectGetMaxY(titleLabel.frame)),
                        STORY_TEXT_WIDTH,
                                                            dekDimensions.height);

                thumbnailView.imageRep = story.inlineImage.thumbImage;
                [thumbnailView loadImage];

                result = cell;
            }
            else if (indexPath.row == self.stories.count)
            {
                NSString *MyIdentifier = @"moreArticles";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
                if (cell == nil)
                {
                    // Set up the cell
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
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
                if (moreArticlesLabel)
                {
                    NSInteger remainingArticlesToLoad = (!self.searchResults) ? (200 - [self.stories count]) : (self.searchTotalAvailableResults - [self.stories count]);
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

                result = cell;
            }
            else
            {
                DDLogError(@"%@ attempted to show non-existent row (%d) with actual count of %d", NSStringFromSelector(_cmd), indexPath.row, self.stories.count);
            }
        }
            break;
    }
    return result;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.stories.count)
    {
        if (!self.xmlParser)
        { // only "load x more..." if no other load is going on
            if (!self.searchResults)
            {
                [self loadFromServer:YES];
            }
            else
            {
                [self loadSearchResultsFromServer:YES forQuery:self.searchQuery];
            }
        }
    }
    else
    {
        StoryDetailViewController *detailViewController = [[StoryDetailViewController alloc] init];
        detailViewController.newsController = self;
        NewsStory *story = self.stories[indexPath.row];
        detailViewController.story = story;

        [self.navigationController pushViewController:detailViewController animated:YES];
    }
}

#pragma mark -
#pragma mark Browsing hooks

- (BOOL)canSelectPreviousStory
{
    NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
    return (currentIndexPath.row > 0);
}

- (BOOL)canSelectNextStory
{
    NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
    return ((currentIndexPath.row + 1) < [self.stories count]);
}

- (NewsStory *)selectPreviousStory
{
    NewsStory *prevStory = nil;
    if ([self canSelectPreviousStory])
    {
        NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
        NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:currentIndexPath.section];
        prevStory = self.stories[prevIndexPath.row];
        [self.tableView selectRowAtIndexPath:prevIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
    return prevStory;
}

- (NewsStory *)selectNextStory
{
    NewsStory *nextStory = nil;
    if ([self canSelectNextStory])
    {
        NSIndexPath *currentIndexPath = [self.tableView indexPathForSelectedRow];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:currentIndexPath.section];
        nextStory = self.stories[nextIndexPath.row];
        [self.tableView selectRowAtIndexPath:nextIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
    return nextStory;
}

@end
