#import <UIKit/UIKit.h>

@protocol MITNewsStoryDataSource;
@protocol MITNewsStoryDelegate;
@protocol MITNewsListDelegate;

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

- (NSString*)reuseIdentifierForRowAtIndexPath:(NSIndexPath*)indexPath;
- (NSUInteger)numberOfCategories;
- (BOOL)isFeaturedCategoryInSection:(NSUInteger)section;
- (NSString*)titleForCategoryInSection:(NSUInteger)section;
- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)section;
- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath;
- (void)didSelectStoryAtIndexPath:(NSIndexPath*)indexPath;

@property (nonatomic) BOOL isCategory;
- (void)setError:(NSString *)errorMessage;
- (void)setProgress:(BOOL)progress;

@end

@protocol MITNewsListDelegate <NSObject>
- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError * error))block;
@end