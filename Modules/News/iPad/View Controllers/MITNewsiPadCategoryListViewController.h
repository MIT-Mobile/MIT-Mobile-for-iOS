#import "MITNewsiPadViewController.h"

@interface MITNewsiPadCategoryListViewController : MITNewsiPadViewController

@property (nonatomic) NSUInteger currentDataSourceIndex;

@property (nonatomic,weak) id<MITNewsStoryDataSource> dataSource;
@property (nonatomic,weak) id<MITNewsStoryDelegate> delegate;

@end
