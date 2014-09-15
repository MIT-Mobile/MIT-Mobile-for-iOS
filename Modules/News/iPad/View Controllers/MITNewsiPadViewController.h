#import <UIKit/UIKit.h>
#import "MITNewsGridViewController.H"
#import "MITNewsListViewController.h"

@class MITNewsStory;
@class MITNewsCategory;

typedef NS_ENUM(NSInteger, MITNewsPresentationStyle) {
    MITNewsPresentationStyleGrid = 0,
    MITNewsPresentationStyleList
};

@interface MITNewsiPadViewController : UIViewController

@property (nonatomic, weak) IBOutlet MITNewsGridViewController *gridViewController;
@property (nonatomic, weak) IBOutlet MITNewsListViewController *listViewController;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, readonly, weak) UIViewController *activeViewController;
@property (nonatomic, getter=isSearching) BOOL searching;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
- (void)reloadData;


@property (nonatomic,readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) MITNewsPresentationStyle presentationStyle;
@property (nonatomic) BOOL showsFeaturedStories;

- (IBAction)searchButtonWasTriggered:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsGrid:(UIBarButtonItem*)sender;
- (IBAction)showStoriesAsList:(UIBarButtonItem*)sender;
- (void)reloadData;
- (void)updateNavigationItem:(BOOL)animated;
- (void)setPresentationStyle:(MITNewsPresentationStyle)style animated:(BOOL)animated;

@end

@protocol MITNewsStoryDataSource <NSObject>
@optional
- (BOOL)viewController:(UIViewController*)viewController isFeaturedCategoryInSection:(NSUInteger)section;
- (void)loadMoreItemsForCategoryInSection:(NSUInteger)section completion:(void(^)(NSError *error))block;
- (BOOL)canLoadMoreItemsForCategoryInSection:(NSUInteger)section;
- (BOOL)refreshItemsForCategoryInSection:(NSUInteger)section completion:(void(^)(NSError *error))block;

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