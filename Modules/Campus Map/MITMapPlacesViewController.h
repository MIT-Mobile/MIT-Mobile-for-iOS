#import <UIKit/UIKit.h>
@class MapSelectionController;

@interface RecentSearchesViewController : UITableViewController
@property (nonatomic, weak) MapSelectionController* mapSelectionController;
- (id)initWithMapSelectionController:(MapSelectionController*)mapSelectionController;

@end
