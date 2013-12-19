#import <UIKit/UIKit.h>
#import "MITFetchedResultsTableViewController.h"

@class MITMapPlace;
@protocol MITMapPlaceSelectionDelegate;

@interface MITMapPlacesViewController : MITFetchedResultsTableViewController
@property (nonatomic,weak) id<MITMapPlaceSelectionDelegate> delegate;

- (instancetype)initWithPredicate:(NSPredicate*)predicate
                  sortDescriptors:(NSArray*)sortDescriptors;
- (void)didSelectPlaces:(NSArray*)places;
@end

@protocol MITMapPlaceSelectionDelegate <NSObject>
- (void)placesController:(MITMapPlacesViewController*)controller didSelectPlaces:(NSArray*)objects;
- (void)placesControllerDidCancelSelection:(MITMapPlacesViewController*)controller;
@end