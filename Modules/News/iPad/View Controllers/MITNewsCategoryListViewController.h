#import "MITNewsListViewController.h"

@protocol MITNewsListDelegate;

@interface MITNewsCategoryListViewController : MITNewsListViewController

@property (nonatomic, weak) id<MITNewsListDelegate, MITNewsStoryDelegate> delegate;

@end

@protocol MITNewsListDelegate <NSObject>

- (void)setToolbarStatusUpdating;
- (void)setToolbarStatusUpdated;
- (void)refreshToolbarStatus;
@end