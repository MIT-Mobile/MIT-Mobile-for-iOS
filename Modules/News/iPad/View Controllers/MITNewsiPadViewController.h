#import <UIKit/UIKit.h>

@class MITNewsStory;
@class MITNewsCategory;

typedef NS_ENUM(NSInteger, MITNewsPresentationStyle) {
    MITNewsPresentationStyleGrid = 0,
    MITNewsPresentationStyleList
};

@interface MITNewsiPadViewController : UIViewController
@property (nonatomic) MITNewsPresentationStyle presentationStyle;
@property (nonatomic) BOOL showsFeaturedStories;

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsGrid:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsList:(UIBarButtonItem*)sender;
@end

@protocol MITNewsStoryDataSource <NSObject>
- (BOOL)viewController:(UIViewController*)viewController isFeaturedCategoryAtIndex:(NSUInteger)index;

- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController;
- (NSString*)viewController:(UIViewController*)viewController titleForCategoryAtIndex:(NSUInteger)index;

- (NSUInteger)viewController:(UIViewController*)viewController numberOfStoriesInCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index;
@end

@protocol MITNewsStoryDelegate <NSObject>
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectStoryAtIndexPath:(NSIndexPath*)indexPath;
@end