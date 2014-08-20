#import "MITNewsiPadViewController.h"
#import "MITNewsDataSource.h"

@interface MITNewsiPadCategoryViewController : MITNewsiPadViewController

@property (nonatomic, retain) MITNewsDataSource *dataSource;
@property (nonatomic, strong) NSString *categoryTitle;
@property (nonatomic) MITNewsPresentationStyle presentationStyle;
@property (nonatomic, strong) NSDate *previousLastUpdated;
@property (nonatomic) MITNewsPresentationStyle previousPresentationStyle;

@end
