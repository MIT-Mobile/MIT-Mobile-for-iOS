#import <UIKit/UIKit.h>
#import "StoryXMLParser.h"

typedef enum {
    NewsCategoryIdTopNews = 0,
    NewsCategoryIdEngineering = 1,
    NewsCategoryIdScience = 2,
    NewsCategoryIdManagement = 3,
    NewsCategoryIdArchitecture = 5,
    NewsCategoryIdHumanities = 6,
    NewsCategoryIdCampus = 99
} NewsCategoryId;

@class MITSearchEffects;
@class NewsStory;

@interface StoryListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, StoryXMLParserDelegate> {
	UITableView *storyTable;
    NSArray *stories;
    NSArray *categories;
    NSInteger activeCategoryId;
	StoryXMLParser *xmlParser;
    
    NSArray *navButtons;
    
	// Nav Scroll View
	UIScrollView *navScrollView;
	UIButton *leftScrollButton;
	UIButton *rightScrollButton;  

	// Search bits
	NSString *searchQuery;
	NSArray *searchResults;
	NSInteger searchTotalAvailableResults;
	UISearchBar *theSearchBar;
	MITSearchEffects *searchOverlay;
	
	BOOL hasBookmarks;
	BOOL showingBookmarks;
	
    UIView *activityView;
    
    NSIndexPath *tempTableSelection;
    BOOL lastRequestSucceeded;
}

@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NSString *searchQuery;
@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, assign) NSInteger activeCategoryId;
@property (nonatomic, retain) StoryXMLParser *xmlParser;

- (void)pruneStories;
- (void)switchToCategory:(NewsCategoryId)category;
- (void)loadFromCache;
- (void)loadFromServer:(BOOL)loadMore;
- (void)loadSearchResultsFromCache;
- (void)loadSearchResultsFromServer:(BOOL)loadMore forQuery:(NSString *)query;
- (BOOL)canSelectPreviousStory;
- (BOOL)canSelectNextStory;
- (NewsStory *)selectPreviousStory;
- (NewsStory *)selectNextStory;
@end
