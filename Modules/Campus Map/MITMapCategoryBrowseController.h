#import <UIKit/UIKit.h>
#import "MITMapModel.h"

@interface MITMapCategoryBrowseController : UITableViewController

- (id)init:(void (^)(NSOrderedSet* selectedPlaces))placesSelected;
@end