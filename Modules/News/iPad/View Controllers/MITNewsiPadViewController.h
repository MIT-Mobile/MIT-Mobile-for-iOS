#import <UIKit/UIKit.h>

@class MITNewsStory;
@class MITNewsCategory;

typedef NS_ENUM(NSInteger, MITNewsPresentationStyle) {
    MITNewsPresentationStyleGrid = 0,
    MITNewsPresentationStyleList
};

@interface MITNewsiPadViewController : UIViewController
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) MITNewsPresentationStyle presentationStyle;
@property (nonatomic) BOOL showsFeaturedStories;

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsGrid:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsList:(UIBarButtonItem*)sender;
@end

@protocol MITNewsStoryDataSource <NSObject>
@optional
- (BOOL)viewController:(UIViewController*)viewController isFeaturedCategoryInSection:(NSUInteger)section;

@required
- (NSUInteger)numberOfCategoriesInViewController:(UIViewController*)viewController;
- (NSString*)viewController:(UIViewController*)viewController titleForCategoryInSection:(NSUInteger)section;

- (NSUInteger)viewController:(UIViewController*)viewController numberOfStoriesForCategoryInSection:(NSUInteger)section;
- (MITNewsStory*)viewController:(UIViewController*)viewController storyAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section;
@end

@protocol MITNewsStoryDelegate <NSObject>
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectCategoryInSection:(NSUInteger)index;
- (MITNewsStory*)viewController:(UIViewController *)viewController didSelectStoryAtIndex:(NSUInteger)index forCategoryInSection:(NSUInteger)section;
@end