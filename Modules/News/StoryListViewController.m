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

@interface StoryListViewController (Private)

- (void)setupNavScroller;
- (void)setupNavScrollButtons;
- (void)buttonPressed:(id)sender;

- (void)setupActivityIndicator;
- (void)setStatusText:(NSString *)text;
- (void)setLastUpdated:(NSDate *)date;
- (void)setProgress:(CGFloat)value;

- (void)showSearchBar;
- (void)hideSearchBar;
- (void)releaseSearchBar;

- (void)pruneStories:(BOOL)asyncPrune;

@end

@implementation StoryListViewController

@synthesize stories = _stories;
@synthesize searchResults;
@synthesize searchQuery;
@synthesize categories = _categories;
@synthesize activeCategoryId;
@synthesize xmlParser;

NSString *const NewsCategoryTopNews = @"Top News";
NSString *const NewsCategoryCampus = @"Campus";
NSString *const NewsCategoryEngineering = @"Engineering";
NSString *const NewsCategoryScience = @"Science";
NSString *const NewsCategoryManagement = @"Management";
NSString *const NewsCategoryArchitecture = @"Architecture";
NSString *const NewsCategoryHumanities = @"Humanities";

NewsCategoryId buttonCategories[] = {
        NewsCategoryIdTopNews, NewsCategoryIdCampus,
        NewsCategoryIdEngineering, NewsCategoryIdScience,
        NewsCategoryIdManagement, NewsCategoryIdArchitecture,
        NewsCategoryIdHumanities
};

NSString *titleForCategoryId(NewsCategoryId category_id) {
    NSString *result = nil;
    switch (category_id)
    {
        case NewsCategoryIdTopNews:
            result = NewsCategoryTopNews;
            break;
        case NewsCategoryIdCampus:
            result = NewsCategoryCampus;
            break;
        case NewsCategoryIdEngineering:
            result = NewsCategoryEngineering;
            break;
        case NewsCategoryIdScience:
            result = NewsCategoryScience;
            break;
        case NewsCategoryIdManagement:
            result = NewsCategoryManagement;
            break;
        case NewsCategoryIdArchitecture:
            result = NewsCategoryArchitecture;
            break;
        case NewsCategoryIdHumanities:
            result = NewsCategoryHumanities;
            break;
        default:
            break;
    }
    return result;
}

- (void)loadView
{
    [super loadView];

    self.navigationItem.title = @"MIT News";
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Headlines" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)] autorelease];

    self.stories = [NSArray array];
    self.searchQuery = nil;
    self.searchResults = nil;

    tempTableSelection = nil;

    NSMutableArray *newCategories = [NSMutableArray array];
    NSInteger i, count = sizeof(buttonCategories) / sizeof(NewsCategoryId);
    for (i = 0; i < count; i++)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category_id == %d", buttonCategories[i]];
        NSManagedObject *aCategory = [[CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate] lastObject];
        if (!aCategory)
        {
            aCategory = [CoreDataManager insertNewObjectForEntityForName:NewsCategoryEntityName];
        }
        [aCategory setValue:[NSNumber numberWithInteger:buttonCategories[i]] forKey:@"category_id"];
        [aCategory setValue:[NSNumber numberWithInteger:0] forKey:@"expectedCount"];
        [newCategories addObject:aCategory];
    }
    self.categories = newCategories;

    [self pruneStories];
    // reduce number of saved stories to 10 when app quits
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pruneStories)
                                                 name:@"UIApplicationWillTerminateNotification"
                                               object:nil];

    // Story Table view
    storyTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    storyTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    storyTable.delegate = self;
    storyTable.dataSource = self;
    storyTable.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [self.view addSubview:storyTable];
    [storyTable release];
}

- (void)viewDidLoad
{
    [self setupNavScroller];

    // set up results table
    storyTable.frame = CGRectMake(0, navScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navScrollView.frame.size.height);
    [self setupActivityIndicator];

    [self loadFromCache];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // show / hide the bookmarks category
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
    NSMutableArray *allBookmarkedStories = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
    hasBookmarks = ([allBookmarkedStories count] > 0) ? YES : NO;
    [self setupNavScrollButtons];
    if (showingBookmarks)
    {
        [self loadFromCache];
        if (!hasBookmarks)
        {
            [self buttonPressed:[navButtons objectAtIndex:0]];
        }
    }
    // Unselect the selected row
    [tempTableSelection release];
    tempTableSelection = [[storyTable indexPathForSelectedRow] retain];
    if (tempTableSelection)
    {
        [storyTable beginUpdates];
        [storyTable deselectRowAtIndexPath:tempTableSelection animated:YES];
        [storyTable endUpdates];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (tempTableSelection)
    {
        [storyTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:tempTableSelection] withRowAnimation:UITableViewRowAnimationNone];
        [tempTableSelection release];
        tempTableSelection = nil;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    storyTable = nil;
    navScrollView = nil;
    [navButtons release];
    navButtons = nil;
    [activityView release];
    activityView = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationWillTerminateNotification" object:nil];
    self.stories = nil;
    self.searchQuery = nil;
    self.searchResults = nil;
    self.categories = nil;
    self.xmlParser = nil;
    [super dealloc];
}


- (void)pruneStories
{
    [self pruneStories:YES];
}

- (void)pruneStories:(BOOL)asyncPrune
{
    
    void (*dispatch_func)(dispatch_queue_t,dispatch_block_t) = NULL;
    
    if (asyncPrune)
    {
        dispatch_func = &dispatch_async;
    }
    else
    {
        dispatch_func = &dispatch_sync;
    }
    
    (*dispatch_func)(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
        context.undoManager = nil;
        context.mergePolicy = NSOverwriteMergePolicy;
        [context lock];
        
        NSPredicate *notBookmarkedPredicate = [NSPredicate predicateWithFormat:@"(bookmarked == nil) || (bookmarked == NO)"];
        
        // bskinner (note): This is legacy code from 1.x. It was added to clean up
        //  duplicate, un-bookmarked articles when upgrading from 1.x to 2.x.
        //  On all new installs this ends up being a NOOP.
        if (![[NSUserDefaults standardUserDefaults] boolForKey:MITNewsTwoFirstRunKey])
        {
            NSEntityDescription *newsStoryEntity = [NSEntityDescription entityForName:NewsStoryEntityName
                                                               inManagedObjectContext:context];
            
            NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
            fetchRequest.entity = newsStoryEntity;
            fetchRequest.predicate = notBookmarkedPredicate;
            
            NSArray *results = [context executeFetchRequest:fetchRequest
                                                      error:NULL];
            for (NSManagedObject *result in results)
            {
                [context deleteObject:result];
            }
            [[NSUserDefaults standardUserDefaults] setBool:YES
                                                    forKey:MITNewsTwoFirstRunKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        {
            NSEntityDescription *newsStoryEntity = [NSEntityDescription entityForName:NewsStoryEntityName
                                                               inManagedObjectContext:context];
            
            NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
            fetchRequest.entity = newsStoryEntity;
            fetchRequest.predicate = notBookmarkedPredicate;
            fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"postDate" ascending:NO]];
            
            NSArray *stories = [context executeFetchRequest:fetchRequest
                                                      error:NULL];
            
            NSMutableDictionary *savedArticles = [NSMutableDictionary dictionary];
            for (NewsStory *story in stories)
            {
                BOOL storySaved = NO;
                
                for (NSManagedObject *category in story.categories)
                {
                    NSNumber *categoryID = [category valueForKey:@"category_id"];
                    NSMutableSet *categoryStories = [savedArticles objectForKey:categoryID];
                    
                    if (categoryStories == nil)
                    {
                        categoryStories = [NSMutableSet set];
                        [savedArticles setObject:categoryStories
                                          forKey:categoryID];
                    }
                    
                    BOOL shouldSave = storySaved = (([categoryStories count] < 10) &&
                                                    (story.postDate != nil) &&
                                                    ([story.postDate compare:[NSDate date]] != NSOrderedDescending));
                    if (shouldSave)
                    {
                        [categoryStories addObject:story];
                    }
                }
            
                if (storySaved == NO) 
                {
                    [context deleteObject:story];
                }
            }
            
            [savedArticles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSLog(@"Category %@ has %d articles after pruning", key, [obj count]);
            }];
        }
        
        NSError *error = nil;
        [context save:&error];
        
        if (error)
        {
            ELog(@"[News] Failed to save pruning context: %@", [error localizedDescription]);
        }
        
        [context unlock];
        [context release];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadFromCache];
        });
    });
}


#pragma mark - Category selector
- (void)setupNavScroller
{
    // Nav Scroller View
    navScrollView = [[NavScrollerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44.0)];
    navScrollView.navScrollerDelegate = self;

    [self.view addSubview:navScrollView];
}

- (void)setupNavScrollButtons
{
    [navScrollView removeAllButtons];

    // add search button

    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *searchImage = [UIImage imageNamed:MITImageNameSearch];
    [searchButton setImage:searchImage forState:UIControlStateNormal];
    searchButton.adjustsImageWhenHighlighted = NO;
    searchButton.tag = SEARCH_BUTTON_TAG; // random number that won't conflict with news categories

    [navScrollView addButton:searchButton shouldHighlight:NO];

    if (hasBookmarks)
    {
        UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *bookmarkImage = [UIImage imageNamed:MITImageNameBookmark];
        [bookmarkButton setImage:bookmarkImage forState:UIControlStateNormal];
        bookmarkButton.adjustsImageWhenHighlighted = NO;
        bookmarkButton.tag = BOOKMARK_BUTTON_TAG; // random number that won't conflict with news categories
        [navScrollView addButton:bookmarkButton shouldHighlight:NO];
    }
    // add pile of text buttons

    // create buttons for nav scroller view
    NSArray *buttonTitles = [NSArray arrayWithObjects:
                                             NewsCategoryTopNews, NewsCategoryCampus,
                                             NewsCategoryEngineering,
                                             NewsCategoryScience, NewsCategoryManagement,
                                             NewsCategoryArchitecture, NewsCategoryHumanities,
                                             nil];

    //NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:[buttonTitles count]];

    NSInteger i = 0;
    for (NSString *buttonTitle in buttonTitles)
    {
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aButton.tag = buttonCategories[i];
        [aButton setTitle:buttonTitle forState:UIControlStateNormal];
        i++;
        [navScrollView addButton:aButton shouldHighlight:YES];
    }

    UIButton *homeButton = [navScrollView buttonWithTag:self.activeCategoryId];
    [navScrollView buttonPressed:homeButton];
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
    if (!theSearchBar)
    {
        theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 44.0)];
        theSearchBar.tintColor = SEARCH_BAR_TINT_COLOR;
        theSearchBar.alpha = 0.0;
        [self.view addSubview:theSearchBar];
    }

    if (!searchController)
    {
        CGRect frame = CGRectMake(0.0, theSearchBar.frame.size.height, self.view.frame.size.width,
                                  self.view.frame.size.height - (theSearchBar.frame.size.height + activityView.frame.size.height));
        searchController = [[MITSearchDisplayController alloc] initWithFrame:frame searchBar:theSearchBar contentsController:self];
        searchController.delegate = self;
    }

    [self.view bringSubviewToFront:theSearchBar];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.4];
    theSearchBar.alpha = 1.0;
    [UIView commitAnimations];

    [searchController setActive:YES animated:YES];
}

- (void)hideSearchBar
{
    if (theSearchBar)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.4];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(releaseSearchBar)];
        theSearchBar.alpha = 0.0;
        [UIView commitAnimations];
    }
}

- (void)releaseSearchBar
{
    [theSearchBar removeFromSuperview];
    [theSearchBar release];
    theSearchBar = nil;

    [searchController release];
    searchController = nil;
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
    [self hideSearchBar];
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
        if ([self.searchResults count] > 0)
        {
            [storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        self.searchResults = nil;
        [self loadFromCache];
    }
}

#pragma mark -
#pragma mark News activity indicator

- (void)setupActivityIndicator
{
    activityView = [[UIView alloc] initWithFrame:CGRectZero];
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
    [loadingLabel release];

    CGSize labelSize = [loadingLabel.text sizeWithFont:loadingLabel.font forWidth:self.view.bounds.size.width lineBreakMode:UILineBreakModeTailTruncation];

    [self.view addSubview:activityView];

    CGFloat bottom = CGRectGetMaxY(storyTable.frame);
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
    [progressBar release];

    UILabel *updatedLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, activityView.frame.size.width - 16, activityView.frame.size.height)];
    updatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    updatedLabel.tag = 12;
    updatedLabel.text = @"";
    updatedLabel.textColor = [UIColor colorWithHexString:@"#DDDDDD"];
    updatedLabel.font = [UIFont boldSystemFontOfSize:14.0];
    updatedLabel.textAlignment = UITextAlignmentRight;
    updatedLabel.backgroundColor = [UIColor blackColor];
    updatedLabel.opaque = YES;
    [activityView addSubview:updatedLabel];
    [updatedLabel release];

    // shrink table down to accomodate
    CGRect frame = storyTable.frame;
    frame.size.height = frame.size.height - height;
    storyTable.frame = frame;
}

#pragma mark -
#pragma mark Story loading

// TODO break off all of the story loading and paging mechanics into a separate NewsDataManager
// Having all of the CoreData logic stuffed into here makes for ugly connections from story views back to this list view
// It also forces odd behavior of the paging controls when a memory warning occurs while looking at a story

- (void)switchToCategory:(NewsCategoryId)category
{
    if (category != self.activeCategoryId)
    {
        if (self.xmlParser)
        {
            [self.xmlParser abort]; // cancel previous category's request if it's still going
            self.xmlParser = nil;
        }
        self.activeCategoryId = category;
        self.stories = nil;
        if ([self.stories count] > 0)
        {
            [storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        [storyTable reloadData];
        showingBookmarks = (category == BOOKMARK_BUTTON_TAG) ? YES : NO;
        [self loadFromCache]; // makes request to server if no request has been made this session
    }
}

- (void)refresh:(id)sender
{
    if (!self.searchResults)
    {
        // get active category
        NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];

        // set its expectedCount to 0
        [aCategory setValue:[NSNumber numberWithInteger:0] forKey:@"expectedCount"];

        // reload
        [self loadFromCache];
    }
    else
    {
        [self loadSearchResultsFromServer:NO forQuery:self.searchQuery];
    }

}

- (void)loadFromCache
{
    // if showing bookmarks, show those instead
    if (showingBookmarks)
    {
        [self setStatusText:@""];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bookmarked == YES"];
        NSMutableArray *allBookmarkedStories = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
        self.stories = allBookmarkedStories;

    }
    else
    {
        // load what's in CoreData, up to categoryCount
        NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                    //[NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"postDate" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"story_id" ascending:NO],
                                    nil];
        
        NSPredicate *predicate = nil;
        if (self.activeCategoryId == NewsCategoryIdTopNews)
        {
            predicate = [NSPredicate predicateWithFormat:@"(topStory != nil) && (topStory == YES)"];
        }
        else
        {
            predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id == %d", self.activeCategoryId];
        }

        // if maxLength == 0, nothing's been loaded from the server this session -- show up to 10 results from core data
        // else show up to maxLength
        NSMutableArray *results = [NSMutableArray arrayWithArray:[CoreDataManager objectsForEntity:NewsStoryEntityName
                                                                                 matchingPredicate:predicate
                                                                                   sortDescriptors:sortDescriptors]];
        if ([results count] && ([[[results objectAtIndex:0] featured] boolValue] == NO))
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
        
        NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];
        NSDate *lastUpdatedDate = [aCategory valueForKey:@"lastUpdated"];

        [self setLastUpdated:lastUpdatedDate];

        NSInteger maxLength = [[aCategory valueForKey:@"expectedCount"] integerValue];
        NSInteger resultsCount = [results count];
        if (maxLength == 0)
        {
            [self loadFromServer:NO]; // this creates a loop which will keep trying until there is at least something in this category
            // TODO: make sure this doesn't become an infinite loop.
            maxLength = 10;
        }
        if (maxLength > resultsCount)
        {
            maxLength = resultsCount;
        }
        self.stories = [results subarrayWithRange:NSMakeRange(0, maxLength)];
    }
    [storyTable reloadData];
    [storyTable flashScrollIndicators];
}

- (void)loadFromServer:(BOOL)loadMore
{
    // make an asynchronous call for more stories

    // start new request
    NewsStory *lastStory = [self.stories lastObject];
    NSInteger lastStoryId = (loadMore) ? [lastStory.story_id integerValue] : 0;
    if (self.xmlParser)
    {
        [self.xmlParser abort];
    }
    self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
    xmlParser.delegate = self;
    [xmlParser loadStoriesForCategory:self.activeCategoryId
                         afterStoryId:lastStoryId
                                count:10]; // count doesn't do anything at the moment (no server support)
}

- (void)loadSearchResultsFromCache
{
    // make a predicate for everything with the search flag
    NSPredicate *predicate = nil;
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:postDateSortDescriptor, storyIdSortDescriptor, nil];
    [storyIdSortDescriptor release];
    [postDateSortDescriptor release];

    predicate = [NSPredicate predicateWithFormat:@"searchResult == YES"];

    // show everything that comes back
    NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];

    NSInteger resultsCount = [results count];

    [self setStatusText:@""];
    if (resultsCount == 0)
    {
        UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:nil message:@"No matching articles found." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
        [alertView show];
        self.searchResults = nil;
        self.stories = nil;
        [storyTable reloadData];
    }
    else
    {
        self.searchResults = results;
        self.stories = results;

        // hide translucent overlay
        [searchController hideSearchOverlayAnimated:YES];

        // show results
        [storyTable reloadData];
        [storyTable flashScrollIndicators];
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    DLog(@"make sure search bar is first responder right now");
}

- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query
{
    if (self.xmlParser)
    {
        [self.xmlParser abort];
    }
    self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
    xmlParser.delegate = self;

    [xmlParser loadStoriesforQuery:query afterIndex:((loadMore) ? [self.searchResults count] : 0) count:10];
}

#pragma mark -
#pragma mark StoryXMLParser delegation

- (void)parserDidStartDownloading:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser)
    {
        [self setProgress:0.1];
        [storyTable reloadData];
    }
}

- (void)parserDidStartParsing:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser)
    {
        [self setProgress:0.3];
    }
}

- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone
{
    if (parser == self.xmlParser)
    {
        [self setProgress:0.3 + 0.7 * percentDone * 0.01];
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error
{
    if (parser == self.xmlParser)
    {
        // TODO: communicate download failure to user
        if ([error code] == NSURLErrorNotConnectedToInternet)
        {
            ELog(@"News download failed because there's no net connection");
        }
        else
        {
            ELog(@"Download failed for parser %@ with error %@", parser, [error userInfo]);
        }
        [self setStatusText:@"Update failed"];

        [MITMobileWebAPI showErrorWithHeader:@"News"];
        if ([self.stories count] > 0)
        {
            [storyTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error
{
    if (parser == self.xmlParser)
    {
        // TODO: communicate parse failure to user
        [self setStatusText:@"Update failed"];
        [MITMobileWebAPI showErrorWithHeader:@"News"];
        if ([self.stories count] > 0)
        {
            [storyTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser
{
    if (parser == self.xmlParser)
    {
        // basic category request
        if (!parser.isSearch)
        {
            NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];
            NSInteger length = [[aCategory valueForKey:@"expectedCount"] integerValue];
            if (length == 0)
            { // fresh load of category, set its updated date
                [aCategory setValue:[NSDate date] forKey:@"lastUpdated"];
            }
            length += [self.xmlParser.addedStories count];
            [aCategory setValue:[NSNumber numberWithInteger:length] forKey:@"expectedCount"];
            if (!parser.loadingMore && [self.stories count] > 0)
            {
                [storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            self.xmlParser = nil;
            
            if (parser.loadingMore == NO)
            {
                [self pruneStories:NO];
            }
            
            [self loadFromCache];
        }
                // result of a search request
        else
        {
            searchTotalAvailableResults = self.xmlParser.totalAvailableResults;
            if (!parser.loadingMore && [self.stories count] > 0)
            {
                [storyTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
    UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
    UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
    UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
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
    [formatter release];
}

- (void)setProgress:(CGFloat)value
{
    UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
    UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
    UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
    loadingLabel.hidden = NO;
    progressBar.hidden = NO;
    updatedLabel.hidden = YES;
    progressBar.progress = value;
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
            if (!showingBookmarks && // showing bookmarks
                !(searchResults && n >= searchTotalAvailableResults) && // showing all search results
                !(!searchResults && n >= 200))
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
        titleView = [UITableView ungroupedSectionHeaderWithTitle:[NSString stringWithFormat:@"%d found", searchTotalAvailableResults]];
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
                NewsStory *story = [self.stories objectAtIndex:indexPath.row];

                static NSString *StoryCellIdentifier = @"StoryCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StoryCellIdentifier];

                UILabel *titleLabel = nil;
                UILabel *dekLabel = nil;
                StoryThumbnailView *thumbnailView = nil;

                if (cell == nil)
                {
                    // Set up the cell
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:StoryCellIdentifier] autorelease];

                    // Title View
                    titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    titleLabel.tag = 1;
                    titleLabel.font = [UIFont boldSystemFontOfSize:STORY_TITLE_FONT_SIZE];
                    titleLabel.numberOfLines = 0;
                    titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
                    [cell.contentView addSubview:titleLabel];
                    [titleLabel release];

                    // Summary View
                    dekLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    dekLabel.tag = 2;
                    dekLabel.font = [UIFont systemFontOfSize:STORY_DEK_FONT_SIZE];
                    dekLabel.textColor = [UIColor colorWithHexString:@"#0D0D0D"];
                    dekLabel.highlightedTextColor = [UIColor whiteColor];
                    dekLabel.numberOfLines = 0;
                    dekLabel.lineBreakMode = UILineBreakModeTailTruncation;
                    [cell.contentView addSubview:dekLabel];
                    [dekLabel release];

                    thumbnailView = [[StoryThumbnailView alloc] initWithFrame:CGRectMake(0, 0, THUMBNAIL_WIDTH, THUMBNAIL_WIDTH)];
                    thumbnailView.tag = 3;
                    [cell.contentView addSubview:thumbnailView];
                    [thumbnailView release];

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
                CGSize titleDimensions = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
                availableHeight -= titleDimensions.height;

                CGSize dekDimensions = CGSizeZero;
                // if not even one line will fit, don't show the deck at all
                if (availableHeight > dekLabel.font.leading)
                {
                    dekDimensions = [dekLabel.text sizeWithFont:dekLabel.font constrainedToSize:CGSizeMake(STORY_TEXT_WIDTH, availableHeight) lineBreakMode:UILineBreakModeTailTruncation];
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
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
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
                    [moreArticlesLabel release];
                }

                UILabel *moreArticlesLabel = (UILabel *)[cell viewWithTag:1234];
                if (moreArticlesLabel)
                {
                    NSInteger remainingArticlesToLoad = (!searchResults) ? (200 - [self.stories count]) : (searchTotalAvailableResults - [self.stories count]);
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
                ELog(@"%@ attempted to show non-existent row (%d) with actual count of %d", NSStringFromSelector(_cmd), indexPath.row, self.stories.count);
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
        NewsStory *story = [self.stories objectAtIndex:indexPath.row];
        detailViewController.story = story;

        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
    }
}

#pragma mark -
#pragma mark Browsing hooks

- (BOOL)canSelectPreviousStory
{
    NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
    if (currentIndexPath.row > 0)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)canSelectNextStory
{
    NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
    if (currentIndexPath.row + 1 < [self.stories count])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

- (NewsStory *)selectPreviousStory
{
    NewsStory *prevStory = nil;
    if ([self canSelectPreviousStory])
    {
        NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
        NSIndexPath *prevIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row - 1 inSection:currentIndexPath.section];
        prevStory = [self.stories objectAtIndex:prevIndexPath.row];
        [storyTable selectRowAtIndexPath:prevIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
    return prevStory;
}

- (NewsStory *)selectNextStory
{
    NewsStory *nextStory = nil;
    if ([self canSelectNextStory])
    {
        NSIndexPath *currentIndexPath = [storyTable indexPathForSelectedRow];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:currentIndexPath.row + 1 inSection:currentIndexPath.section];
        nextStory = [self.stories objectAtIndex:nextIndexPath.row];
        [storyTable selectRowAtIndexPath:nextIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
    return nextStory;
}

@end
