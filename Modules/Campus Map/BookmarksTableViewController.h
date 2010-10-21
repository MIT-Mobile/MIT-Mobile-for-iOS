#import <UIKit/UIKit.h>

@class CampusMapViewController;
@class MapSelectionController;

@interface BookmarksTableViewController : UITableViewController 
{	
	MapSelectionController* _mapSelectionController;
}

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;


@property (nonatomic, assign) MapSelectionController* mapSelectionController;

@end
