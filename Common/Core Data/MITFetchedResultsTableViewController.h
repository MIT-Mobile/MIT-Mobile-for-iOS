#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MITFetchedResultsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) NSFetchRequest *fetchRequest;
@property (nonatomic,getter = shouldUpdateTableOnResultsChange) BOOL updateTableOnResultsChange;

- (id)initWithFetchRequest:(NSFetchRequest*)fetchRequest;
@end
