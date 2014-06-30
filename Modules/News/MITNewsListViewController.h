#import <UIKit/UIKit.h>

@protocol MITNewsStoryDataSource;
@protocol MITNewsStoryDelegate;

@class MITNewsCategory;
@class MITNewsStory;

@interface MITNewsListViewController : UITableViewController
@property (nonatomic,getter = isShowingFeaturedItemsSection) BOOL showFeaturedItemsSection;
@property (nonatomic) NSUInteger maximumNumberOfStoriesPerCategory;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,weak) id<MITNewsStoryDataSource> dataSource;
@property (nonatomic,weak) id<MITNewsStoryDelegate> delegate;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
- (void)reloadData;

- (NSUInteger)numberOfCategories;
- (BOOL)featuredCategoryAtIndex:(NSUInteger)index;
- (NSString*)titleForCategoryAtIndex:(NSUInteger)index;
- (NSUInteger)numberOfStoriesInCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath;
@end