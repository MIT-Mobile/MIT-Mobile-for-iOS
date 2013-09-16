#import <UIKit/UIKit.h>
#import "StoryXMLParser.h"
#import "MITSearchDisplayController.h"
#import "NavScrollerView.h"

DEPRECATED_ATTRIBUTE
typedef NS_ENUM(NSInteger, NewsCategoryId) {
    NewsCategoryIdTopNews = 0,
    NewsCategoryIdEngineering = 1,
    NewsCategoryIdScience = 2,
    NewsCategoryIdManagement = 3,
    NewsCategoryIdArchitecture = 5,
    NewsCategoryIdHumanities = 6,
    NewsCategoryIdCampus = 99,
    NewsCategoryIdInvalid = 1024
};

@class NewsStory;

@interface StoryListViewController : UIViewController
- (void)switchToCategory:(NewsCategoryId)category;
@end
