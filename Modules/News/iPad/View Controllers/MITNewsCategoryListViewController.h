#import "MITNewsListViewController.h"

@protocol MITNewsListDelegate;

@interface MITNewsCategoryListViewController : MITNewsListViewController
@property (nonatomic, weak) id<MITNewsListDelegate, MITNewsStoryDelegate> delegate;
@end

@protocol MITNewsListDelegate <NSObject>
- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError * error))block;
@end