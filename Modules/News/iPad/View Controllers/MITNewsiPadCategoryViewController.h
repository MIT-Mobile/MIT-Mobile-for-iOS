#import "MITNewsiPadViewController.h"
#import "MITNewsDataSource.h"

@interface MITNewsiPadCategoryViewController : MITNewsiPadViewController

@property (nonatomic, retain) MITNewsDataSource *dataSource;
@property (nonatomic, strong) NSString *categoryTitle;
@property (nonatomic) MITNewsPresentationStyle previousPresentationStyle;
@end
