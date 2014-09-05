#import "MITNewsListViewController.h"

@protocol MITNewsListDelegate;

@interface MITNewsCategoryListViewController : MITNewsListViewController

@property (nonatomic, weak) id<MITNewsListDelegate, MITNewsStoryDelegate> delegate;
- (void)setError:(NSString *)errorMessage;
- (void)setProgress:(BOOL)progress;

@end

@protocol MITNewsListDelegate <NSObject>
- (void)getMoreStoriesForSection:(NSInteger)section completion:(void (^)(NSError * error))block;
@end