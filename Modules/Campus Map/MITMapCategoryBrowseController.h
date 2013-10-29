#import <UIKit/UIKit.h>
#import "MITMapModel.h"
#import "MITFetchedResultsTableViewController.h"

@interface MITMapCategoryBrowseController : MITFetchedResultsTableViewController
/** Initializes an instance of the category browser with 
 *  the 'placesSelected' handler block. If a NSManagedObjectContext
 *  is assigned, then the selectedPlaces set will contain concrete
 *  NSManagedObjects, otherwise NSManagedObjectIDs will be returned.
 *  
 *  The managed objects returned by the selection block are instances of
 *  the MapPlace entity.
 *
 *  @related MITMapPlace
 *  @see managedObjectContext
 */
- (id)init:(void (^)(MITMapCategory *category, NSOrderedSet* selectedObjects))selected;
@end