#import <UIKit/UIKit.h>

@class MITNewsStory;
@protocol MITNewsStoryDataSource;
@protocol MITNewsStoryDelegate;

@interface MITNewsGridViewController : UICollectionViewController
@property (nonatomic) NSUInteger numberOfStoriesPerCategory;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,weak) id<MITNewsStoryDataSource> dataSource;
@property (nonatomic,weak) id<MITNewsStoryDelegate> delegate;

- (instancetype)init;

- (NSUInteger)numberOfCategories;
- (BOOL)featuredCategoryAtIndex:(NSUInteger)index;
- (NSString*)titleForCategoryAtIndex:(NSUInteger)index;
- (NSUInteger)numberOfStoriesInCategoryAtIndex:(NSUInteger)index;
- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath;
@end
