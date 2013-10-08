#import <UIKit/UIKit.h>
#import "MITMapModel.h"

@interface MITMapCategoryBrowseController : UITableViewController

/** Initializes an instance of the category browser with 
 *  the 'placesSelected' handler block. The 'selectedPlaces' block
 *  parameter will contain instances of the 'MITMapPlace' class
 */
- (id)init:(void (^)(NSOrderedSet* selectedPlaces))placesSelected;
@end