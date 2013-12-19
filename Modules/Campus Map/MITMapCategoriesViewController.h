#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "MITFetchedResultsTableViewController.h"

@class MITMapCategory;
@protocol MITMapCategoriesDelegate;

@interface MITMapCategoriesViewController : MITFetchedResultsTableViewController
@property (nonatomic,strong) id<MITMapCategoriesDelegate> delegate;

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
- (id)init;
@end

@protocol MITMapCategoriesDelegate <NSObject>
- (void)controller:(MITMapCategoriesViewController*)controller didSelectObjects:(NSArray*)objects inCategory:(MITMapCategory*)category;
- (void)controller:(MITMapCategoriesViewController*)controller didSelectCategory:(MITMapCategory*)category;
- (void)controllerDidCancelSelection:(MITMapCategoriesViewController*)controller;
@end
