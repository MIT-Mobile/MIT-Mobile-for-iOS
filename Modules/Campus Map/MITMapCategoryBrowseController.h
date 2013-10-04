#import <UIKit/UIKit.h>
#import "MITMapModel.h"

typedef void (^MITMapCategorySelectionHandler)(NSOrderedSet *selectedPlaces, NSError *error);

@interface MITMapCategoryBrowseController : UITableViewController

- (id)init:(MITMapCategorySelectionHandler)placesSelected;
@end