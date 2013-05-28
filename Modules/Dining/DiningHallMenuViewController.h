#import <UIKit/UIKit.h>
#import "DiningMenuFilterViewController.h"
#import "CoreDataManager.h"

@class HouseVenue;

@interface DiningHallMenuViewController : UITableViewController <DiningMenuFilterDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) HouseVenue * venue;

@end
