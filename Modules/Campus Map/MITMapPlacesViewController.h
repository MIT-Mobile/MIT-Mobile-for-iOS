#import <UIKit/UIKit.h>
#import "MITFetchedResultsTableViewController.h"

@class MITMapPlace;

@interface MITMapPlacesViewController : MITFetchedResultsTableViewController
- (instancetype)initWithPredicate:(NSPredicate*)predicate
                  sortDescriptors:(NSArray*)sortDescriptors
                        selection:(void (^)(NSOrderedSet *mapPlaces))block;
@end
