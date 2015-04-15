#import <UIKit/UIKit.h>
#import "MITMobiusResourceDataSource.h"

@protocol MITResourceFilterDelegate <NSObject>

- (void)applyQuickParams:(id)object;

@end


@interface MITMobiusQuickSearchTableViewController : UITableViewController

@property (nonatomic) id<MITResourceFilterDelegate> delegate;
@property (nonatomic,strong) MITMobiusResourceDataSource *dataSource;
@property (nonatomic) MITMobiusQuickSearchType typeOfObjects;

@end
