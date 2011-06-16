#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITLoadingActivityView.h"

@class MapSelectionController;

@interface CategoriesTableViewController : UITableViewController <JSONLoadedDelegate> {
	MapSelectionController* _mapSelectionController;
	
	NSMutableArray* _itemsInTable;
	NSString* _headerText;
	BOOL _topLevel;
	BOOL _leafLevel;
	
	MITLoadingActivityView* _loadingView;
}

@property (nonatomic, assign) MapSelectionController* mapSelectionController;
@property (nonatomic, retain) NSMutableArray* itemsInTable;
@property (nonatomic, retain) NSString* headerText;
@property BOOL topLevel;
@property BOOL leafLevel;

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;
-(id) initWithMapSelectionController:(MapSelectionController *)mapSelectionController andStyle:(UITableViewStyle)style;
-(void) executeServerCategoryRequestWithQuery:(NSString *)query;

@end
