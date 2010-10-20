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

@interface StoryListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, StoryXMLParserDelegate> {
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

    UIView *activityView;
    
    NSIndexPath *tempTableSelection;
    BOOL lastRequestSucceeded;
}

@property (nonatomic, retain) NSArray *stories;
@property (nonatomic, retain) NSArray *categories;
@property (nonatomic, assign) NSInteger activeCategoryId;
@property (nonatomic, retain) StoryXMLParser *xmlParser;

- (void)pruneStories;
- (void)switchToCategory:(NewsCategoryId)category;
- (void)loadFromCache;
- (void)loadFromServer:(BOOL)loadMore;

@end
