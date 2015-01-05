#import <UIKit/UIKit.h>
#import "MITCollectionViewGridLayout.h"

@class MITNewsStory;
@class MITCollectionViewCellSizer;

@protocol MITNewsStoryDataSource;
@protocol MITNewsStoryDelegate;
@protocol MITNewsGridDelegate;

@interface MITNewsGridViewController : UICollectionViewController <MITCollectionViewDelegateNewsGrid>
@property(nonatomic) NSUInteger numberOfStoriesPerCategory;
@property(nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic,readonly) MITCollectionViewCellSizer *collectionViewCellSizer;

@property(nonatomic,weak) id<MITNewsStoryDataSource> dataSource;
@property(nonatomic,weak) id<MITNewsStoryDelegate, MITNewsGridDelegate> delegate;

@property(nonatomic) NSUInteger numberOfColumnsForPortraitOrientation;
@property(nonatomic) NSUInteger numberOfColumnsForLandscapeOrientation;

- (instancetype)init;

- (NSUInteger)numberOfCategories;
- (BOOL)isFeaturedCategoryInSection:(NSUInteger)section;
- (NSString*)titleForCategoryInSection:(NSUInteger)section;
- (NSUInteger)numberOfStoriesForCategoryInSection:(NSUInteger)section;
- (MITNewsStory*)storyAtIndexPath:(NSIndexPath*)indexPath;
- (void)updateLoadingMoreCellString;

#pragma mark Subclass methods
- (NSString*)identifierForCellAtIndexPath:(NSIndexPath*)indexPath;
- (void)registerNib:(UINib*)nib forDynamicCellWithReuseIdentifier:(NSString*)reuseIdentifier;
- (CGFloat)heightForItemAtIndexPath:(NSIndexPath*)indexPath withWidth:(CGFloat)width;

@property (nonatomic) BOOL showSingleCategory;
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic) BOOL storyUpdateInProgress;
@property (nonatomic) BOOL storyRefreshInProgress;

@end

@protocol MITNewsGridDelegate <NSObject>
- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError * error))block;
@end