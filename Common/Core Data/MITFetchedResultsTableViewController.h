#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface MITFetchedResultsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
@property (nonatomic,readonly,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,readonly,strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic,strong) NSFetchRequest *fetchRequest;
@property (nonatomic,getter = shouldUpdateTableOnResultsChange) BOOL updateTableOnResultsChange;

- (id)init;
- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;
- (id)initWithFetchRequest:(NSFetchRequest*)fetchRequest;
@end
