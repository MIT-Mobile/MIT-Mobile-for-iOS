#import <UIKit/UIKit.h>
#import "MITFetchedResultsTableViewController.h"

@class MapSelectionController;

@interface MITMapBookmarksViewController : MITFetchedResultsTableViewController

/** Created a view controller for browsing the user's saved bookmarks.
 *  Once one or more placed is selected the passed block will be called
 *  with the current category and an ordered set of NSManagedObjectIDs.
 *
 *  The managed objects IDs returned by the selection block resolve to instances of
 *  the MapPlace entity.
 *
 *  @related MITMapPlace
 */
- (id)init:(void (^)(NSOrderedSet* mapPlaceIDs))placesSelected;
@end
