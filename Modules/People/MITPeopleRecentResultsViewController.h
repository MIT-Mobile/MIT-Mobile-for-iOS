#import <UIKit/UIKit.h>
#import "MITPeopleSearchRootViewController.h"
#import "MITPeopleSearchHandler.h"

@protocol MITPeopleRecentsViewControllerDelegate <NSObject>

- (void) didSelectRecentSearchTerm:(NSString *)searchTerm;

@optional

- (void) didClearRecents;

@end

@interface MITPeopleRecentResultsViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) MITPeopleSearchHandler *searchHandler;
@property (nonatomic, weak) id<MITPeopleRecentsViewControllerDelegate> delegate;

- (void)reloadRecentResultsWithFilterString:(NSString *)filterString;

@end
