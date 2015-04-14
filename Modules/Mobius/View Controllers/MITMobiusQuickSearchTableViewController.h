#import <UIKit/UIKit.h>

#import "MITMobiusResourceDataSource.h"

@interface MITMobiusQuickSearchTableViewController : UITableViewController

@property (nonatomic,strong) MITMobiusResourceDataSource *dataSource;
@property (nonatomic) MITMobiuQuickSearchType typeOfObjects;

@end
