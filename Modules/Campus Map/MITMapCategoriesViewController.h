#import <UIKit/UIKit.h>

@class MITMapCategory;

@interface MITMapCategoriesViewController : UITableViewController
/** Initializes an instance of the category browser with 
 *  the 'placesSelected' handler block. Once one or more placed is selected
 *  the passed block will be called with the current category and
 *  an ordered set of NSManagedObjectIDs.
 *  
 *  The managed object IDs returned by the selection block resolve to instances of
 *  the MapPlace entity.
 *
 *  @related MITMapPlace
 *  @related MITMapCategory
 */
- (id)init:(void (^)(MITMapCategory *category, NSOrderedSet* mapPlaceIDs))selected;
@end