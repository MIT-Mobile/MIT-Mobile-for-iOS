#import "MITNewsGridViewController.h"

@protocol MITNewsGridDelegate;

@interface MITNewsCategoryGridViewController : MITNewsGridViewController
@property (nonatomic, weak) id<MITNewsGridDelegate, MITNewsStoryDelegate> delegate;
@property (nonatomic) BOOL storyUpdateInProgress;
@end

@protocol MITNewsGridDelegate <NSObject>
- (void)getMoreStoriesForSection:(NSInteger *)section completion:(void (^)(NSError * error))block;
@end