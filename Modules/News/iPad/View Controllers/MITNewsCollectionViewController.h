#import <UIKit/UIKit.h>

@class MITNewsCategory;
@class MITNewsStory;
@protocol MITNewsCollectionViewDelegate;
@protocol MITNewsCollectionViewDataSource;

@interface MITNewsCollectionViewController : UICollectionViewController
@property (nonatomic) NSUInteger numberOfStoriesPerCategory;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,weak) id<MITNewsCollectionViewDataSource> dataSource;
@property (nonatomic,weak) id<MITNewsCollectionViewDelegate> delegate;

- (instancetype)init;

- (NSInteger)numberOfCategories;
- (MITNewsCategory*)categoryForIndex:(NSInteger)index;
- (NSInteger)numberOfStoriesInCategory:(MITNewsCategory*)category;
- (MITNewsStory*)storyAtIndex:(NSInteger)index inCategory:(MITNewsCategory*)category;
@end

@protocol MITNewsCollectionViewDataSource <NSObject>
- (NSInteger)numberOfCategoriesInNewsCollectionController:(MITNewsCollectionViewController*)collectionControllers;
- (MITNewsCategory*)newsCollectionController:(MITNewsCollectionViewController*)collectionController categoryAtIndex:(NSInteger)index;

- (NSInteger)newsCollectionController:(MITNewsCollectionViewController*)collectionController numberOfStoriesInCategory:(MITNewsCategory*)category;
- (MITNewsStory*)newsCollectionController:(MITNewsCollectionViewController*)collectionController storyAtIndex:(NSInteger)index inCategory:(MITNewsCategory*)category;
@end

@protocol MITNewsCollectionViewDelegate <NSObject>
- (void)newsCollectionController:(MITNewsCollectionViewController*)collectionController didSelectStory:(MITNewsStory*)story;
- (void)newsCollectionController:(MITNewsCollectionViewController*)collectionController didSelectCategory:(MITNewsCategory*)category;
@end
