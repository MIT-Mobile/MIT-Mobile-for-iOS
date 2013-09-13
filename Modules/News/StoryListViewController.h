#import <UIKit/UIKit.h>
#import "StoryXMLParser.h"
#import "MITSearchDisplayController.h"
#import "NavScrollerView.h"

// TODO: Get this out of here! We should be getting this
// data from the news API, not hardcoding it.
typedef enum {
    NewsCategoryIdTopNews = 0,
    NewsCategoryIdEngineering = 1,
    NewsCategoryIdScience = 2,
    NewsCategoryIdManagement = 3,
    NewsCategoryIdArchitecture = 5,
    NewsCategoryIdHumanities = 6,
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
@end
