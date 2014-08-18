#import <UIKit/UIKit.h>
#import "MITCollectionViewGridLayout.h"

@class MITNewsStory;
@protocol MITNewsStoryDataSource;
@protocol MITNewsStoryDelegate;

@interface MITNewsGridViewController : UICollectionViewController <MITCollectionViewDelegateNewsGrid>
@property (nonatomic) NSUInteger numberOfStoriesPerCategory;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,weak) id<MITNewsStoryDataSource> dataSource;
@property (nonatomic,weak) id<MITNewsStoryDelegate> delegate;

@property (nonatomic) NSUInteger numberOfColumnsForPortraitOrientation;
@property (nonatomic) NSUInteger numberOfColumnsForLandscapeOrientation;

- (instancetype)init;

- (NSUInteger)numberOfCategories;
- (BOOL)isFeaturedCategoryInSection:(NSUInteger)section;
- (NSString*)titleForCategoryInSection:(NSUInteger)section;
- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)section;
- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath;

#pragma mark Subclass methods
- (NSString*)identifierForCellAtIndexPath:(NSIndexPath*)indexPath;
- (void)registerNib:(UINib*)nib forDynamicCellWithReuseIdentifier:(NSString*)reuseIdentifier;
- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath withWidth:(CGFloat)width;
@end
