#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MITMobileWebAPI.h"

@interface CorridorListViewController : UITableViewController <NSFetchedResultsControllerDelegate, JSONLoadedDelegate> {
	NSFetchedResultsController *frc;
	NSString *loadingState;
}

@property (nonatomic, retain) NSFetchedResultsController *frc;
@property (nonatomic, retain) NSString *loadingState;

@end
