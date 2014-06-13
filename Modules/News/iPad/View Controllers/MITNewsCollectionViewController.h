#import <UIKit/UIKit.h>

@class MITNewsCategory;
@class MITNewsStory;
@protocol MITNewsCollectionViewDelegate;

@interface MITNewsCollectionViewController : UICollectionViewController
@property (nonatomic) NSUInteger numberOfStoriesPerCategory;
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,weak) id<MITNewsCollectionViewDelegate> selectionDelegate;

- (instancetype)init;
@end

@protocol MITNewsCollectionViewDelegate <NSObject>
- (void)newsCollectionController:(MITNewsCollectionViewController*)collectionController didSelectStory:(MITNewsStory*)story;
- (void)newsCollectionController:(MITNewsCollectionViewController*)collectionController didSelectCategory:(MITNewsCategory*)category;
@end
