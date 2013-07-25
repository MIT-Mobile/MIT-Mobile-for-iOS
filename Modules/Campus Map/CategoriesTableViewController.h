#import <UIKit/UIKit.h>
#import "MITMobileWebAPI.h"
#import "MITLoadingActivityView.h"

@class MapSelectionController;

@interface CategoriesTableViewController : UITableViewController <JSONLoadedDelegate>
@property (nonatomic, weak) MapSelectionController* mapSelectionController;
@property (nonatomic, strong) NSMutableArray* itemsInTable;
@property (nonatomic, strong) NSString* headerText;
@property BOOL topLevel;
@property BOOL leafLevel;

-(id) initWithMapSelectionController:(MapSelectionController*)mapSelectionController;
-(id) initWithMapSelectionController:(MapSelectionController *)mapSelectionController andStyle:(UITableViewStyle)style;
-(void) executeServerCategoryRequestWithQuery:(NSString *)query;

@end
