#import "MITNewsViewController.h"
#import "MITNewsDataSource.h"

@interface MITNewsCategoryViewController : MITNewsViewController

@property (nonatomic, retain) MITNewsDataSource *dataSource;
@property (nonatomic, strong) NSString *categoryTitle;
@property (nonatomic) MITNewsPresentationStyle previousPresentationStyle;
@end
