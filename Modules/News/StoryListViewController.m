#import "MIT_MobileAppDelegate.h"
#import "StoryListViewController.h"
#import "StoryDetailViewController.h"
#import "StoryThumbnailView.h"
#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "UIKit+MITAdditions.h"
#import "TabScrollerBackgroundView.h"

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

@interface StoryListViewController (Private)

- (void)setupNavScroller;
- (void)sideButtonPressed:(id)sender;
- (void)buttonPressed:(id)sender;

- (void)setupActivityIndicator;

@end

@implementation StoryListViewController

@synthesize stories;
@synthesize categories;
@synthesize activeCategoryId;
@synthesize xmlParser;

NSString * const NewsCategoryTopNews = @"Top News";
NSString * const NewsCategoryCampus = @"Campus";
NSString * const NewsCategoryEngineering = @"Engineering";
NSString * const NewsCategoryScience = @"Science";
NSString * const NewsCategoryManagement = @"Management";
NSString * const NewsCategoryArchitecture = @"Architecture";
NSString * const NewsCategoryHumanities = @"Humanities";

NSString *titleForCategoryId(NewsCategoryId category_id) {
    NSString *result = nil;
    switch (category_id) {
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

- (void)loadView {
	[super loadView];
	
    self.navigationItem.title = @"MIT News";
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Headlines" style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)] autorelease];
	
    self.stories = [NSArray array];
    
    tempTableSelection = nil;
    lastRequestSucceeded = YES;
    
    // reduce number of saved stories to 10 when app quits
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pruneStories) name:@"UIApplicationWillTerminateNotification" object:nil];
    
	// Story Table view
	storyTable = [[UITableView alloc] initWithFrame:self.view.bounds];
    storyTable.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	storyTable.delegate = self;
	storyTable.dataSource = self;
    storyTable.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
	[self.view addSubview:storyTable];
}

- (void)viewDidLoad {
    
    /*
     module start
        load active category
        register for connectiondetector notifications
            if no connection is detected, "Load more articles..." gets greyed out, becomes "Not connected"
            when connection becomes available, enable "Load more articles..."
     
     load category
        load whatever's in core data
        spawn thread for new request
        show progress indicator, but let user interact with old articles until then
        on request success, load latest articles from core data
     
     load more articles...
        request from server starting from last story_id in table
        show progress indicator as above, also turn "load more" into a progress indicator
        on success, load that range from core data
        on failure, show uialertview with message
     */
    [self setupNavScroller];
    storyTable.frame = CGRectMake(0, navScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navScrollView.frame.size.height);
    [self setupActivityIndicator];

    [self loadFromCache];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Unselect the selected row
    [tempTableSelection release];
	tempTableSelection = [[storyTable indexPathForSelectedRow] retain];
	if (tempTableSelection) {
        [storyTable beginUpdates];
		[storyTable deselectRowAtIndexPath:tempTableSelection animated:YES];
        [storyTable endUpdates];
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (tempTableSelection) {
        [storyTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:tempTableSelection] withRowAnimation:UITableViewRowAnimationNone];
        [tempTableSelection release];
        tempTableSelection = nil;
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [storyTable release];
    storyTable = nil;
    [navScrollView release];
    navScrollView = nil;
    [navButtons release];
    navButtons = nil;
    [activityView release];
    activityView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // find which rows are visible
    NSMutableArray *visibleRows = [[[storyTable indexPathsForVisibleRows] mutableCopy] autorelease];
    // fault everything not currently visible
    NSInteger i = 0;
    for (NewsStory *aStory in self.stories) {
        // documentation doesn't mention a guarantee of -indexPathsForVisibleRows ordering
        BOOL visible = NO;
        for (NSIndexPath *aPath in visibleRows) {
            if (aPath.row == i) {
                visible = YES;
                [visibleRows removeObject:aPath]; // ok to modify visibleRows within this fast enumeration because the loop does not continue after removal
                break;
            }
        }
        if (!visible) {
            [[CoreDataManager managedObjectContext] refreshObject:aStory mergeChanges:NO];
        }
        i++;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIApplicationWillTerminateNotification" object:nil];
	[navScrollView release];
    navScrollView = nil;
	[storyTable release];
    storyTable = nil;
    [stories release];
    stories = nil;
    [categories release];
    categories = nil;
    [xmlParser release];
    xmlParser = nil;
    [super dealloc];
}

- (void)pruneStories {
    // retain only the 10 most recent stories for each category. (here and when saving, because we may have crashed before having a chance to prune the story list last time)
    
    // because stories are added to Core Data in separate threads, there may be merge conflicts. this thread wins when we're pruning
    NSManagedObjectContext *context = [CoreDataManager managedObjectContext];
    id originalMergePolicy = [context mergePolicy];
    [context setMergePolicy:NSOverwriteMergePolicy];

    NewsCategoryId allCategories[] = {
        NewsCategoryIdTopNews, NewsCategoryIdCampus,
        NewsCategoryIdEngineering, NewsCategoryIdScience, 
        NewsCategoryIdManagement, NewsCategoryIdArchitecture, 
        NewsCategoryIdHumanities
    };
    
    NSMutableSet *allStoriesToSave = [NSMutableSet setWithCapacity:100];
    NSInteger i, count = sizeof(allCategories) / sizeof(NewsCategoryId);
    for (i = 0; i < count; i++) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id == %d", allCategories[i]];
        NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
        NSArray *categoryStories = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:[NSArray arrayWithObject:postDateSortDescriptor]];
        // only the 10 most recent
        if ([categoryStories count] > 10) {
            [allStoriesToSave addObjectsFromArray:[categoryStories subarrayWithRange:NSMakeRange(0, 10)]];
        } else {
            [allStoriesToSave addObjectsFromArray:categoryStories];
        }
        [postDateSortDescriptor release];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    NSMutableArray *allStories = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
    NSMutableSet *allStoriesToDelete = [NSMutableSet setWithArray:allStories];
    [allStoriesToDelete minusSet:allStoriesToSave];
    [CoreDataManager deleteObjects:[allStoriesToDelete allObjects]];
    [CoreDataManager saveData];
    
    // put merge policy back where it was before we started
    [[CoreDataManager managedObjectContext] setMergePolicy:originalMergePolicy];
}

#pragma mark -
#pragma mark Category selector

- (void)setupNavScroller {
    // Nav Scroller View

    // load this first in order to find out its height
    UIImage *backgroundImage = [UIImage imageNamed:MITImageNameScrollTabBackgroundOpaque];
    
	UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 828, backgroundImage.size.height)];

	UIImage *buttonImage = [UIImage imageNamed:MITImageNameScrollTabSelectedTab];
	UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];

	// create buttons for nav scroller view
    NSArray *buttonTitles = [[NSArray alloc] initWithObjects:
                             NewsCategoryTopNews, NewsCategoryCampus, 
                             NewsCategoryEngineering, 
                             NewsCategoryScience, NewsCategoryManagement, 
                             NewsCategoryArchitecture, NewsCategoryHumanities, 
                             nil];
    NewsCategoryId buttonCategories[] = {
        NewsCategoryIdTopNews, NewsCategoryIdCampus, 
        NewsCategoryIdEngineering, NewsCategoryIdScience, 
        NewsCategoryIdManagement, NewsCategoryIdArchitecture, 
        NewsCategoryIdHumanities
    };
    
    
    NSMutableArray *newCategories = [NSMutableArray array];
    NSInteger i, count = sizeof(buttonCategories) / sizeof(NewsCategoryId);
    for (i = 0; i < count; i++) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"category_id == %d", buttonCategories[i]];
        NSManagedObject *aCategory = [[CoreDataManager objectsForEntity:NewsCategoryEntityName matchingPredicate:predicate] lastObject];
        if (!aCategory) {
            aCategory = [CoreDataManager insertNewObjectForEntityForName:NewsCategoryEntityName];
        }
        [aCategory setValue:[NSNumber numberWithInteger:buttonCategories[i]] forKey:@"category_id"];
        [aCategory setValue:[NSNumber numberWithInteger:0] forKey:@"expectedCount"];
        [newCategories addObject:aCategory];
    }
    self.categories = newCategories;
    
    activeCategoryId = NewsCategoryIdTopNews;
    
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:[buttonTitles count]];
    
    CGFloat leftOffset = 5.0;
    
    i = 0;
    for (NSString *buttonTitle in buttonTitles) {
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        aButton.tag = buttonCategories[i];
        [aButton setBackgroundImage:nil forState:UIControlStateNormal];
        [aButton setBackgroundImage:stretchableButtonImage forState:UIControlStateHighlighted];            
        [aButton setTitle:buttonTitle forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor colorWithHexString:@"#FCCFCF"] forState:UIControlStateNormal];
        [aButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        aButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        [aButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        aButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 1.0, 0); // needed to center text vertically within button
        
        CGSize newSize = [aButton.titleLabel.text sizeWithFont:aButton.titleLabel.font];
        newSize.width += SCROLL_TAB_HORIZONTAL_PADDING * 2 + SCROLL_TAB_HORIZONTAL_MARGIN;
        newSize.height = stretchableButtonImage.size.height;
        CGRect frame = aButton.frame;
        frame.size = newSize;
        frame.origin.x += leftOffset;
        frame.origin.y = 3.0;
        aButton.frame = frame;
        leftOffset += frame.size.width;
        
        [buttons addObject:aButton];
        [contentView addSubview:aButton];
        i++;
    }
    
    // make Home button active by default
    UIButton *homeButton = [buttons objectAtIndex:0];
    [homeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[homeButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
    
    [buttonTitles release];
    navButtons = buttons;

    // now that the buttons have all been added, update the content frame
    CGRect newFrame = contentView.frame;
    newFrame.size.width = leftOffset + SCROLL_TAB_HORIZONTAL_PADDING;
    contentView.frame = newFrame;
    
	// Create nav scroll view and add it to the hierarchy
    navScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, backgroundImage.size.height)];
	navScrollView.delegate = self;
    navScrollView.scrollsToTop = NO; // otherwise this competes with the story list for status bar taps
	navScrollView.contentSize = contentView.frame.size;
	navScrollView.showsHorizontalScrollIndicator = NO;
    navScrollView.opaque = NO;

//  if we want to make the navScrollView translucent, it will need to have a separate background view. -colorWithPatternImage: doesn't seem to do transparency
//    TabScrollerBackgroundView *bgView = [[TabScrollerBackgroundView alloc] initWithFrame:navScrollView.frame];
//    [self.view addSubview:bgView];
//    [bgView release];
//    
//    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
//    self.navigationController.navigationBar.translucent = YES;
    
	[navScrollView setBackgroundColor:[UIColor colorWithPatternImage:backgroundImage]];

	[navScrollView addSubview:contentView];
	[contentView release];
	[self.view addSubview:navScrollView];
	
	// Prep left and right scrollers
	UIImage *leftScrollImage = [UIImage imageNamed:MITImageNameScrollTabLeftEndCap];
    leftScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftScrollButton setImage:leftScrollImage forState:UIControlStateNormal];
	CGRect imageFrame = CGRectMake(0,0,leftScrollImage.size.width,leftScrollImage.size.height);
    leftScrollButton.frame = imageFrame;
	leftScrollButton.hidden = YES;
    [leftScrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:leftScrollButton];
	
	UIImage *rightScrollImage = [UIImage imageNamed:MITImageNameScrollTabRightEndCap];
    rightScrollButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightScrollButton setImage:rightScrollImage forState:UIControlStateNormal];
	imageFrame = CGRectMake(self.view.frame.size.width - rightScrollImage.size.width,0,rightScrollImage.size.width,rightScrollImage.size.height);
    rightScrollButton.frame = imageFrame;
	rightScrollButton.hidden = NO;
    [rightScrollButton addTarget:self action:@selector(sideButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:rightScrollButton];
}

- (void)sideButtonPressed:(id)sender {
    CGPoint offset = navScrollView.contentOffset;
    if (sender == leftScrollButton) {
        NSInteger i, count = [navButtons count];
        for (i = count - 1; i >= 0; i--) {
            UIButton *tab = [navButtons objectAtIndex:i];
            if (CGRectGetMinX(tab.frame) - offset.x < 0) {
                CGRect rect = tab.frame;
                rect.origin.x -= leftScrollButton.frame.size.width - 8.0;
                [navScrollView scrollRectToVisible:rect animated:YES];
                break;
            }
        }
    } else if (sender == rightScrollButton) {
        for (UIButton *tab in navButtons) {
            if (CGRectGetMaxX(tab.frame) - (offset.x + navScrollView.frame.size.width) > 0) {
                CGRect rect = tab.frame;
                rect.origin.x += rightScrollButton.frame.size.width - 8.0;
                [navScrollView scrollRectToVisible:rect animated:YES];
                break;
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([scrollView isEqual:navScrollView]) {
		CGPoint offset = scrollView.contentOffset;
		if (offset.x <= 0) {
			leftScrollButton.hidden = YES;
		} else {
			leftScrollButton.hidden = NO;
		}
		if (offset.x >= navScrollView.contentSize.width - navScrollView.frame.size.width) {
			rightScrollButton.hidden = YES;
		} else {
			rightScrollButton.hidden = NO;
		}
	}
}

- (void)buttonPressed:(id)sender {
    UIButton *pressedButton = (UIButton *)sender;
    NSMutableArray *buttons = [navButtons mutableCopy];

    if ([buttons containsObject:pressedButton]) {
        [buttons removeObject:pressedButton];
        
        UIImage *buttonImage = [UIImage imageNamed:MITImageNameScrollTabSelectedTab];
        UIImage *stretchableButtonImage = [buttonImage stretchableImageWithLeftCapWidth:15 topCapHeight:0];
        
        [pressedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [pressedButton setBackgroundImage:stretchableButtonImage forState:UIControlStateNormal];
        
        for (UIButton *aButton in buttons) {
            [aButton setTitleColor:[UIColor colorWithHexString:@"#FCCFCF"] forState:UIControlStateNormal];
            [aButton setBackgroundImage:nil forState:UIControlStateNormal];
        }
        
        [self switchToCategory:pressedButton.tag];
    }
    
    [buttons release];
}

#pragma mark -
#pragma mark News activity indicator

- (void)setupActivityIndicator {
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

- (void)switchToCategory:(NewsCategoryId)category {
    NSString *categoryTitle = titleForCategoryId(category);
    
    if (!categoryTitle) {
        NSLog(@"Invalid category %d passed to %s", category, __PRETTY_FUNCTION__);
    }
    
    if (category != self.activeCategoryId) {
        self.activeCategoryId = category;
        self.stories = nil;
        [storyTable reloadData];
        if (self.xmlParser) {
            [self.xmlParser abort]; // cancel previous category's request if it's still going
            self.xmlParser = nil;
        }
        [self loadFromCache]; // makes request to server if no request has been made this session
    }
}

- (void)refresh:(id)sender {
    // get active category
    NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];

    // set its expectedCount to 0
    [aCategory setValue:[NSNumber numberWithInteger:0] forKey:@"expectedCount"];
    
    // reload
    [self loadFromCache];
}

- (void)loadFromCache {
    // load what's in CoreData, up to categoryCount
    NSPredicate *predicate = nil;
    NSSortDescriptor *featuredSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"featured" ascending:NO];
    NSSortDescriptor *postDateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"postDate" ascending:NO];
    NSSortDescriptor *storyIdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"story_id" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:featuredSortDescriptor, postDateSortDescriptor, storyIdSortDescriptor, nil];
    [storyIdSortDescriptor release];
    [postDateSortDescriptor release];
    [featuredSortDescriptor release];
    
    if (self.activeCategoryId == NewsCategoryIdTopNews) {
        predicate = [NSPredicate predicateWithFormat:@"topStory == YES"];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"ANY categories.category_id == %d", self.activeCategoryId];
    }
    
    // if maxLength == 0, nothing's been loaded from the server this session -- show up to 10 results from core data
    // else show up to maxLength
    NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate sortDescriptors:sortDescriptors];
    NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];
    NSDate *lastUpdatedDate = [aCategory valueForKey:@"lastUpdated"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
    UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
    UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
    if (lastUpdatedDate) {
        updatedLabel.text = [NSString stringWithFormat:@"Last updated %@", [formatter stringFromDate:lastUpdatedDate]];
    } else {
        updatedLabel.text = nil;
    }

    updatedLabel.hidden = NO;
    loadingLabel.hidden = YES;
    progressBar.hidden = YES;
    [formatter release];
    
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

	[storyTable reloadData];
    [storyTable flashScrollIndicators];
}

- (void)loadFromServer:(BOOL)loadMore {
    // make an asynchronous call for more stories
    
    // TODO: disable "Load more articles..." until load finishes
    
    // start new request
    NewsStory *lastStory = [self.stories lastObject];
    NSInteger lastStoryId = (loadMore) ? [lastStory.story_id integerValue] : 0;
    
	self.xmlParser = [[[StoryXMLParser alloc] init] autorelease];
	xmlParser.delegate = self;
    [xmlParser loadStoriesForCategory:self.activeCategoryId afterStoryId:lastStoryId count:10]; // count doesn't do anything at the moment (no server support)
}

#pragma mark -
#pragma mark StoryXMLParser delegation

- (void)parserDidStartDownloading:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
        UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
        UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
        UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
        loadingLabel.hidden = NO;
        progressBar.hidden = NO;
        updatedLabel.hidden = YES;
        progressBar.progress = 0.1;
    }
}

- (void)parserDidStartParsing:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
        UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
        progressBar.progress = 0.3;
    }
}

- (void)parser:(StoryXMLParser *)parser didMakeProgress:(CGFloat)percentDone {
    if (parser == self.xmlParser) {
        UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
        progressBar.progress = 0.3 + 0.7 * percentDone * 0.01;
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithDownloadError:(NSError *)error {
    if (parser == self.xmlParser) {
        // TODO: communicate download failure to user
        if ([error code] == NSURLErrorNotConnectedToInternet) {
            NSLog(@"News download failed because there's no net connection");
        } else {
            NSLog(@"Download failed for parser %@ with error %@", parser, [error userInfo]);
        }
        UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
        UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
        UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
        loadingLabel.hidden = YES;
        progressBar.hidden = YES;
        updatedLabel.hidden = NO;
        updatedLabel.text = @"Update failed";
        if (lastRequestSucceeded) {
            lastRequestSucceeded = NO;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update failed" message:@"Please check your connection and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        if ([self.stories count] > 0) {
            [storyTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parser:(StoryXMLParser *)parser didFailWithParseError:(NSError *)error {
    if (parser == self.xmlParser) {
        // TODO: communicate parse failure to user
        UILabel *loadingLabel = (UILabel *)[activityView viewWithTag:10];
        UIProgressView *progressBar = (UIProgressView *)[activityView viewWithTag:11];
        UILabel *updatedLabel = (UILabel *)[activityView viewWithTag:12];
        loadingLabel.hidden = YES;
        progressBar.hidden = YES;
        updatedLabel.hidden = NO;
        updatedLabel.text = @"Update failed";
        if (lastRequestSucceeded) {
            lastRequestSucceeded = NO;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Update failed" message:@"Please check your connection and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        if ([self.stories count] > 0) {
            [storyTable deselectRowAtIndexPath:[NSIndexPath indexPathForRow:[self.stories count] inSection:0] animated:YES];
        }
    }
}

- (void)parserDidFinishParsing:(StoryXMLParser *)parser {
    if (parser == self.xmlParser) {
        NSManagedObject *aCategory = [[self.categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category_id == %d", self.activeCategoryId]] lastObject];
        NSInteger length = [[aCategory valueForKey:@"expectedCount"] integerValue];
        if (length == 0) { // fresh load of category, set its updated date
            [aCategory setValue:[NSDate date] forKey:@"lastUpdated"];
        }
        length += [self.xmlParser.newStories count];
        [aCategory setValue:[NSNumber numberWithInteger:length] forKey:@"expectedCount"];
        lastRequestSucceeded = YES;
        self.xmlParser = nil;
        [self loadFromCache];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource and UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.stories.count > 0) ? 1 : 0;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return [NSString stringWithFormat:@"%d stories", self.stories.count];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger n = 0;
    switch (section) {
        case 0:
            n = self.stories.count + 1; // + 1 for the "Load more articles..." row
            break;
    }
	return n;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat rowHeight = 0;

    switch (indexPath.section) {
        case 0: {
            if (indexPath.row < self.stories.count) {
                rowHeight = THUMBNAIL_WIDTH;
            } else {
                rowHeight = 50; // "Load more articles..."
            }

            break;
        }
    }
    return rowHeight;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *result = nil;
    
    switch (indexPath.section) {
        case 0: {
            if (indexPath.row < self.stories.count) {
                NewsStory *story = [self.stories objectAtIndex:indexPath.row];
                
                static NSString *StoryCellIdentifier = @"StoryCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:StoryCellIdentifier];
                
                UILabel *titleLabel = nil;
                UILabel *dekLabel = nil;
                StoryThumbnailView *thumbnailView = nil;
                
                if (cell == nil) {
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
                if (availableHeight > dekLabel.font.leading) {
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
            else if (indexPath.row == self.stories.count) {
                NSString *MyIdentifier = @"moreArticles";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
                if (cell == nil) {
                    // Set up the cell
                    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    
                    UILabel *moreArticlesLabel = [[UILabel alloc] initWithFrame:cell.frame];
                    moreArticlesLabel.font = [UIFont boldSystemFontOfSize:16];
                    moreArticlesLabel.numberOfLines = 1;
                    moreArticlesLabel.textColor = [UIColor colorWithHexString:@"#990000"];
                    moreArticlesLabel.text = @"Load 10 more articles...";
                    [moreArticlesLabel sizeToFit];
                    CGRect frame = moreArticlesLabel.frame;
                    frame.origin.x = 10;
                    frame.origin.y = ((NSInteger)(50.0 - moreArticlesLabel.frame.size.height)) / 2;
                    moreArticlesLabel.frame = frame;
                    
                    [cell.contentView addSubview:moreArticlesLabel];
                    [moreArticlesLabel release];
                }
                result = cell;
            } else {
                NSLog(@"%s attempted to show non-existent row (%d) with actual count of %d", _cmd, indexPath.row, self.stories.count);
            }
        }
            break;
    }
    return result;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.row == self.stories.count)
	{
		[self loadFromServer:TRUE];
	}
	else
	{
        StoryDetailViewController *detailViewController = [[StoryDetailViewController alloc] init];
		NewsStory *story = [self.stories objectAtIndex:indexPath.row];
	
        detailViewController.story = story;
        
        [self.navigationController pushViewController:detailViewController animated:YES];
        [detailViewController release];
	}
}

@end
