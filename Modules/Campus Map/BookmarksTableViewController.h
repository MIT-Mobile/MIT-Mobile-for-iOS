#import <UIKit/UIKit.h>
#import "MITFetchedResultsTableViewController.h"

@class CampusMapViewController;
@class MapSelectionController;

@interface BookmarksTableViewController : MITFetchedResultsTableViewController

/** Initializes an instance of the bookmarks browser using
 *  the 'placesSelected' handler block. The 'selectedPlaces' block
 *  parameter will contain instances of the 'MITMapPlace' class
 */
- (id)init:(void (^)(NSOrderedSet* selectedPlaces))placesSelected;
@end
