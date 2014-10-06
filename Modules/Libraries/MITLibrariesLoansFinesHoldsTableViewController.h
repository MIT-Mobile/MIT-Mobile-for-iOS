#import <UIKit/UIKit.h>

@protocol MITLibrariesUserRefreshDelegate <NSObject>

- (void)refreshUserData;

@end

@interface MITLibrariesLoansFinesHoldsTableViewController : UITableViewController

@property (nonatomic, weak) id<MITLibrariesUserRefreshDelegate> refreshDelegate;
@property (nonatomic, strong) NSArray *items;

- (void)setupTableView;

@end
