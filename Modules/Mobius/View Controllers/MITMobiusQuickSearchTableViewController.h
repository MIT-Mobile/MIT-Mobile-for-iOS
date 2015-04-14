#import <UIKit/UIKit.h>
#import "MITMobiusResourceDataSource.h"

@protocol MITDiningFilterDelegate <NSObject>

- (void)applyQuickParams:(id)object;

@end


@interface MITMobiusQuickSearchTableViewController : UITableViewController

@property (nonatomic) id<MITDiningFilterDelegate> delegate;
@property (nonatomic,strong) MITMobiusResourceDataSource *dataSource;
@property (nonatomic) MITMobiuQuickSearchType typeOfObjects;

@end
