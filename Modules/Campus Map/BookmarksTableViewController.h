#import <UIKit/UIKit.h>

@class CampusMapViewController;
@class MapSelectionController;

@interface BookmarksTableViewController : UITableViewController
@property (nonatomic, weak) MapSelectionController* mapSelectionController;

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;
@end
