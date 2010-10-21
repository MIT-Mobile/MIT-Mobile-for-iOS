#import <UIKit/UIKit.h>
@class MapSelectionController;

@interface RecentSearchesViewController : UITableViewController {

	MapSelectionController* _mapSelectionController;
	
	NSArray* _searches; 
}

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;


@property (nonatomic, assign) MapSelectionController* mapSelectionController;

@end
