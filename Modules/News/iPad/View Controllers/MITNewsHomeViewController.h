#import <UIKit/UIKit.h>

@class MITNewsCategory;
@class MITNewsStory;
@protocol MITNewsStoryDataSource;
@protocol MITNewsStoryDelegate;

@interface MITNewsHomeViewController : UIViewController

@end

@protocol MITNewsStoryDataSource <NSObject>
- (BOOL)viewController:(UIViewController*)viewController categoryAtIndexShouldBeFeatured:(NSUInteger)index;

- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController;
- (NSString*)viewController:(UIViewController*)viewController titleForCategoryAtIndex:(NSUInteger)index;

- (NSUInteger)viewController:(UIViewController*)viewController numberOfItemsInCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndexPath:(NSIndexPath*)indexPath;
@end

@protocol MITNewsStoryDelegate <NSObject>
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectStoryAtIndexPath:(NSIndexPath*)indexPath;
@end