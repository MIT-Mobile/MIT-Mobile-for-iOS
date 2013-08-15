#import <UIKit/UIKit.h>
#import "StoryXMLParser.h"
#import "MITSearchDisplayController.h"
#import "NavScrollerView.h"

typedef enum {
    NewsCategoryIdTopNews = 0,
    NewsCategoryIdEngineering,
    NewsCategoryIdScience,
    NewsCategoryIdManagement,
    NewsCategoryIdArchitecture,
    NewsCategoryIdHumanities,
    NewsCategoryIdCampus = 99
} NewsCategoryId;

@class NewsStory;

@interface StoryListViewController : UIViewController

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
